function M_DAS = compute_das_matrix_general(recon, transducer, transmit)
%COMPUTE_DAS_MATRIX_GENERAL Delay-and-sum matrix for linear and curved
%arrays, with steering and focusing.
%
% General version of compute_das_matrix, under test against it (see
% tests/DelayAndSumTest.m). Construct a sparse matrix that performs
% delay-and-sum reconstruction on element RF data. The matrix is M-by-N,
% where M is the total number of pixels (Nx*Ny) and N is the total number
% of samples in the RF data (Nt*Nelem).
%
% Coordinates follow the PROTEUS convention: x axial (depth), y lateral.
%
% INPUT ARGUMENTS:
%   recon:
%   - x:            axial   coordinates of the reconstruction [m]
%   - y:            lateral coordinates of the reconstruction [m]
%   - c:            speed of sound for the reconstruction [m/s]
%   - t:            time axis of the RF data [s], with respect to the
%                   moment the transmitted wave leaves the first firing
%                   element (time to peak, lens and k-Wave corrections
%                   applied, see initialize_das_parameters)
%   - Fs:           sampling rate of the RF data [Hz]
%   - alpha_th:     threshold angle for apodization [rad]
%   - apodization:  'cosine' (default): cos(pi/2*alpha/alpha_th) taper,
%                   or 'binary': 1 for angles up to alpha_th
%   transducer:
%   - x_el:         axial element coordinates [m]
%   - y_el:         lateral element coordinates [m]
%   - azimuth:      angle of the element normals with the axial axis,
%                   positive towards positive y [rad]
%   - center:       axial coordinate of the centre of curvature (-Inf for a
%                   linear array) [m]
%   - radius:       radius of curvature (Inf for a linear array) [m]
%   transmit (see das_transmit_distance):
%   - focus:        focal distance [m] (Inf: plane wave for a linear array,
%                   diverging wave from the centre of curvature for a
%                   curved array)
%   - steer:        steering angle [rad]
%   - axis_delay:   additional receive time offset [s] (optional, default
%                   0)
%
% OUTPUT:
%   M_DAS:          sparse (Nx*Ny)-by-(Nt*Nelem) delay-and-sum matrix. The
%                   image is reshape(M_DAS*RF(:), Nx, Ny) (depth-by-lateral),
%                   with RF an Nt-by-Nelem matrix.
%
% Partially based on:
% Vincent Perrot, Maxime Polichetti, Francois Varray, Damien Garcia, So you
% think you can DAS? A viewpoint on delay-and-sum beamforming, Ultrasonics,
% Volume 111, 2021, https://doi.org/10.1016/j.ultras.2020.106309.
%
% Rienk Zorgdrager and Guillaume Lajoinie, University of Twente, 2026

%% DEFAULTS
if ~isfield(transmit,'steer')
    transmit.steer = 0;
end
if ~isfield(transmit,'focus')
    transmit.focus = Inf;
end
if ~isfield(transmit,'axis_delay')
    transmit.axis_delay = 0;
end
if ~isfield(recon,'apodization')
    recon.apodization = 'cosine';
end
if ~isfield(transducer,'center')
    transducer.center = -Inf;
    transducer.radius = Inf;
end

%% GRIDS
Nt      = length(recon.t);              % Number of time samples per element
x_el    = transducer.x_el(:)';          % 1-by-Nelem, axial
y_el    = transducer.y_el(:)';          % 1-by-Nelem, lateral
Nelem   = length(x_el);                 % Number of elements

% Image coordinate grid (column arrays, axial index fastest):
[X, Y] = ndgrid(recon.x, recon.y);
X = X(:);
Y = Y(:);
Npixels = numel(X);

%% DELAYS
% Transmit path (Npixels-by-1) and receive path (Npixels-by-Nelem):
d_in   = das_transmit_distance(X, Y, transducer, transmit);
d_back = sqrt((Y-y_el).^2 + (X-x_el).^2);

t_del = d_back/recon.c + d_in/recon.c + transmit.axis_delay;

% Time index (Npixels-by-Nelem):
j = round((t_del - recon.t(1))*recon.Fs) + 1;

%% APODIZATION
% Angle between the element normal and the direction to the pixel:
alpha = atan2(Y-y_el, X-x_el) - transducer.azimuth(:)';

switch recon.apodization
    case 'cosine'
        v = cos(pi/2*alpha/recon.alpha_th);
    case 'binary'
        v = ones(Npixels, Nelem);
    otherwise
        error('compute_das_matrix_general:apodization', ...
            'Unknown apodization ''%s''.', recon.apodization)
end
v(abs(alpha) > recon.alpha_th) = 0;

% No pixels inside the circle of curvature (behind a curved array):
if isfinite(transducer.radius)
    inside = Y.^2 + (X-transducer.center).^2 < transducer.radius^2;
    v(inside,:) = 0;
end

%% SPARSE MATRIX
i = repmat((1:Npixels)', 1, Nelem);   % Pixel index
k = repmat(1:Nelem, Npixels, 1);      % Element index

% Discard samples outside the RF data of each element:
keep = (j >= 1) & (j <= Nt) & (v ~= 0);

% Column index in the stacked RF data (Nt*Nelem):
col = j(keep) + (k(keep)-1)*Nt;

M_DAS = sparse(i(keep), col, v(keep), Npixels, Nt*Nelem);

end
