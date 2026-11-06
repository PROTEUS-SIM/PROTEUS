function source = define_source_transducer(Transducer, Transmit, ...
    Medium, Grid, source_weights, source_mask_idx)
% =========================================================================
% DEFINE THE TRANSDUCER SOURCE: add point sources to the source object
%
% input:    Transducer
%           Transmit
%           Medium
%           Grid
%           source_weights
%           source_mask_idx
%
% output:   source                  the transducer source object
% =========================================================================

% Work in double precision: custom transmit data loaded from mat files
% (pressure signal, delays, apodization) may be single, and before R2025a
% MATLAB cannot multiply the sparse source weights by a single matrix.
p = double(Transmit.PressureSignal);
M = length(p);

% The velocity source of a curved array is normal to its surface. Lateral
% weights of the velocity source (zero for a flat transducer):
curved = isfield(Transducer,'Configuration') && ...
    strcmp(Transducer.Configuration,'Curved');
if curved
    [nx, ny] = surface_normals(Transducer);
end

% If Transducer.SourceType is defined, compensate for the effect of the
% staggered k-Wave grid. See Table 2.1 on p. 14 of the k-Wave manual
% (Manual Version 1.1, August 27, 2016). 
% http://www.k-wave.org/manual/k-wave_user_manual_1.1.pdf
if isfield(Transducer,'SourceType') && ...
        strcmp(Transducer.SourceType,'dipole')

    TransducerX = Transducer;
    TransducerX.integration_points(:,:,1) = ...
        Transducer.integration_points(:,:,1) - Grid.dx/2;

    [source_weights, source_mask_idx] = ...
        recompute_source_weights(TransducerX,Grid);

    if curved
        % The lateral velocity is staggered along y:
        TransducerY = Transducer;
        TransducerY.integration_points(:,:,2) = ...
            Transducer.integration_points(:,:,2) - Grid.dy/2;

        [source_weights_y, source_mask_idx_y] = ...
            recompute_source_weights(TransducerY,Grid);

        [source_weights, source_weights_y, source_mask_idx] = ...
            merge_masks(source_weights, source_mask_idx, ...
            source_weights_y, source_mask_idx_y);
    end
elseif curved
    source_weights_y = source_weights;
end

if isfield(Transducer,'SourceType') && ...
        strcmp(Transducer.SourceType,'monopole')
    t = (0:(M-1))*Grid.dt;
    p = sinc_interpolation(t, p, t+Grid.dt/2);
end

delays  = double(Transducer.integration_transmit_delays);
apod    = double(Transducer.integration_transmit_apodization);
weights = double(Transducer.integration_weights);

% Apply electronic delays:
delays = delays + transpose(double(Transmit.Delays));

% Apply electronic apodization:
apod   = apod.*transpose(double(Transmit.Apodization));

% Pulsing scheme
switch Transmit.SeqPulse
    case 'even'
        apod(1:2:end, :) = 0;
    case 'odd'
        apod(2:2:end, :) = 0;
    case 'minus'
        apod = -apod;
end

delays  = delays(:);
apod    = apod(:);
weights = weights(:);

% Acoustic impedance:    
Z = Medium.SpeedOfSound*Medium.Density;

% Compute signal length required to apply the delays:
N = M + ceil(max(delays)/Grid.dt);

% Apply delay and apodization.
pressure_source = p.*apod;

% Set up frequency axis (Hz)
f = (0:(N-1))/(N*Grid.dt);

% Make symmetric around N/2 to keep time-domain signal real:
f(:,ceil(N/2+1):N) = -(f(:,floor(1+N/2):-1:2));

% Time shift in the frequency domain:
pressure_source = fft(pressure_source,N,2);
pressure_source = pressure_source.*exp(-2*pi*1i*delays*f);
pressure_source = ifft(pressure_source,[],2,'symmetric');

% For previous versions, dipole sources were used for the transducer
% definition (soft baffle).
if ~isfield(Transducer,'SourceType')
    Transducer.SourceType = 'dipole';
end

if strcmp(Transducer.SourceType,'dipole')
    source.u_mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz, 'logical');
    source.u_mask(source_mask_idx) = 1;

    % Multiply the spatial delta function with the velocity source signals
    % of point sources.
    if curved
        source.ux = source_weights   * (pressure_source.*weights.*nx)/Z;
        source.uy = source_weights_y * (pressure_source.*weights.*ny)/Z;
    else
        source.ux = source_weights * (pressure_source.*weights)/Z;
    end
else
    source.p_mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz, 'logical');
    source.p_mask(source_mask_idx) = 1;

    % Multiply the spatial delta function with the pressure source signals
    % of point sources.
    source.p = source_weights * (pressure_source.*weights);
end

end

function [source_weights, source_mask_idx] = ...
    recompute_source_weights(Transducer,Grid)

[sensor, sensor_weights] = define_sensor_transducer(Transducer, Grid);

source_weights  = transpose(sensor_weights);
source_mask_idx = find(logical(sensor.mask));

end

function [nx, ny] = surface_normals(Transducer)
% Axial and lateral components of the outward normal of a curved array at
% each integration point (column arrays).

El = get_element_geometry(Transducer);
x = Transducer.integration_points(:,:,1);
y = Transducer.integration_points(:,:,2);
phi = atan2(y(:), x(:) - El.Center);
nx = cos(phi);
ny = sin(phi);

end

function [Wx, Wy, idx] = merge_masks(Wx, idx_x, Wy, idx_y)
% Express two source weight matrices (Nmask-by-Npoints) on the union of
% their source masks.

idx = union(idx_x, idx_y);
[~, rows_x] = ismember(idx_x, idx);
[~, rows_y] = ismember(idx_y, idx);

Npoints = size(Wx,2);
[i, j, v] = find(Wx);
Wx = sparse(rows_x(i), j, v, numel(idx), Npoints);
[i, j, v] = find(Wy);
Wy = sparse(rows_y(i), j, v, numel(idx), Npoints);

end
