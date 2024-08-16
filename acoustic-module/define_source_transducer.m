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

% For previous versions, dipole sources were used for the transducer
% definition (soft baffle).
if ~isfield(Transducer,'SourceType')
    Transducer.SourceType = 'dipole';
end

delays  = Transducer.integration_transmit_delays;
apod    = Transducer.integration_transmit_apodization;
weights = Transducer.integration_weights;

% Apply electronic delays:
delays = delays + transpose(Transmit.Delays);

% Apply electronic apodization:
apod   = apod.*transpose(Transmit.Apodization);

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
M = length(Transmit.PressureSignal);
N = M + ceil(max(delays)/Grid.dt);

% Apply delay and apodization.
pressure_source = Transmit.PressureSignal.*apod;

% Set up frequency axis (Hz)
f = (0:(N-1))/(N*Grid.dt);

% Make symmetric around N/2 to keep time-domain signal real:
f(:,ceil(N/2+1):N) = -(f(:,floor(1+N/2):-1:2));

% Time shift in the frequency domain:
pressure_source = fft(pressure_source,N,2);
pressure_source = pressure_source.*exp(-2*pi*1i*delays*f);
pressure_source = ifft(pressure_source,[],2,'symmetric');

if strcmp(Transducer.SourceType,'dipole')
    source.u_mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz, 'logical');
    source.u_mask(source_mask_idx) = 1;

    % Multiply the spatial delta function with the velocity source signals
    % of point sources.
    source.ux = source_weights * (pressure_source.*weights)/Z;
else
    source.p_mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz, 'logical');
    source.p_mask(source_mask_idx) = 1;

    % Multiply the spatial delta function with the pressure source signals
    % of point sources.
    source.p = source_weights * (pressure_source.*weights);
end

end