function M_DAS = compute_das_matrix(t, y, x, y_el, c, Fs, focus)
%COMPUTE_DAS_MATRIX Compute delay-and-sum reconstruction matrix. Construct
%a sparse matrix that performs delay-and-sum reconstruction on element RF
%data. The matrix is M-by-N, where M is the total number of pixels (Ny*Nx,
%lateral index fastest) and N is the total number of elements in the RF
%data (Nt*Nelem).
%
% Coordinates follow the PROTEUS convention (x axial, y lateral); note the
% order of the arguments (lateral before axial).
%
% INPUT ARGUMENTS:
% t:      time array corresponding to the RF data (column array)
% y:      lateral coordinates of the reconstruction [m]
% x:      axial   coordinates of the reconstruction [m]
% y_el:   lateral transducer element coordinates [m]
% c:      speed of sound for the reconstruction [m/s]
% Fs:     sampling rate of the RF data
% focus:  lateral focus of the transmit beam
%
% Partially based on:
% Vincent Perrot, Maxime Polichetti, François Varray, Damien Garcia, So you
% think you can DAS? A viewpoint on delay-and-sum beamforming, Ultrasonics,
% Volume 111, 2021, https://doi.org/10.1016/j.ultras.2020.106309.
% (https://www.sciencedirect.com/science/article/pii/S0041624X20302444)
%
% Nathan Blanken, University of Twente, 2023

alpha_th = pi/3; % Threshold angle for apodization

Nx      = length(x);     % Number of pixels in x
Ny      = length(y);     % Number of pixels in y
Npixels = Nx*Ny;         % Total number of pixels
Nt      = length(t);     % Number of time samples per element
Nelem   = length(y_el);  % Number of elements

% Image coordinate grid (lateral index fastest):
[Y, X] = ndgrid(y, x);
Y = Y(:);
X = X(:);

if isfinite(focus) && focus >=0
    error('Only negative focus and infinite focus supported.')
end

F = abs(focus);
if isfinite(F)
    % Focused beam:
    t_del = sqrt((Y-y_el).^2 + X.^2)/c + sqrt((X+F).^2 + Y.^2)/c - F/c;
else
    % Plane wave:
    t_del = sqrt((Y-y_el).^2 + X.^2)/c + X/c;
end

% Compute the indices (i,j,k) of an Npixel-by-Nt-by-Nelem sparse matrix
% with values v:
i = repmat((1:Npixels)',1,Nelem); % Pixel index
j = round((t_del - t(1))*Fs) + 1; % Time index
k = repmat(1:Nelem,Npixels,1);    % Element index
v = ones(Npixels,Nelem);          % Element apodization

% Angle (f-number) dependent apodization (discard elements with a greater 
% angle to the pixel than the threshold angle):
alpha = atan(abs(y_el-Y)./X);
v(alpha > alpha_th) = 0;

% Reshape into column arrays:
i = i(:);
j = j(:);
k = k(:);
v = v(:);

% Exclude indices outside array bounds of RF data:
withinRF = (j>0)&(j<(Nt+1));
i = i(withinRF);
j = j(withinRF);
k = k(withinRF);
v = v(withinRF);

% Reshape Npixel-by-Nt-by-Nelem to Npixel-by-(Nt*Nelem):
j = j + (k-1)*Nt;

% Beamforming matrix:
M_DAS = sparse(i,j,v,Npixels,Nt*Nelem);
end