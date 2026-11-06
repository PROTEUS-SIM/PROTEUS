function [IMG,x,y] = DAS_reconstruction_general(folder,filename_parameters)
%DAS_RECONSTRUCTION_GENERAL Delay-and-sum reconstruction for linear and
%curved arrays, with steering and focusing.
%
% [IMG,x,y] = DAS_RECONSTRUCTION_GENERAL(folder,filename_parameters) has
% the same interface as DAS_reconstruction and can replace it: IMG is
% Nx-by-Ny-by-Nframes, with x the axial and y the lateral pixel
% coordinates (PROTEUS convention). It uses
% initialize_das_parameters and compute_das_matrix_general, which are
% under test against compute_das_matrix (tests/DelayAndSumTest.m).
% Differences with DAS_reconstruction: pixel size lambda/4 instead of
% lambda/5, image starting at the domain boundary Geometry.Domain.Xmin
% instead of 0, and cosine apodization instead of binary.

%==========================================================================
% LOAD DATA AND METADATA
%==========================================================================

% Load the simulation settings:
load(filename_parameters, 'Acquisition', 'SimulationParameters', ...
    'Transmit', 'Transducer', 'Geometry', 'Medium');

% Load RF data (Nelem-by-Nt-by-Nframes)
RF = load_RF_data(folder,Acquisition.PulsingScheme);

% RF data properties:
Nelem = size(RF,1);   % Number of transducer elements
Nt = size(RF,2);      % Number of samples per RF line
Nframes = size(RF,3); % Number of frames
[recon, transducer, transmit] = initialize_das_parameters(Medium, ...
    SimulationParameters, Transducer, Transmit, Geometry, Nelem, Nt);
t = recon.t;
c = recon.c;
x = recon.x;
y = recon.y;

%==========================================================================
% TIME GAIN COMPENSATION (TGC)
%==========================================================================
f0 = Transmit.CenterFrequency;
att = Medium.AttenuationA*(f0*1e-6)^Medium.AttenuationB;
TGC = sqrt(t)/max(sqrt(t)).*10.^(att.*t.*c.*1e2./20./2); 
TGC(t<0) = 0;

RF = RF.*TGC;

%==========================================================================
% COMPUTE DAS MATRIX
%==========================================================================
M_DAS = compute_das_matrix_general(recon, transducer, transmit);

%==========================================================================
% RESHAPE RF DATA AND APPLY DAS MATRIX
%==========================================================================
% Reshape into Nt-by-Nelem matrix and convert to column matrix. This
% creates a vertical stack of single-element RF signals:

disp('Reshaping RF data array')
% Permute because hilbert operates along the columns of the matrix:
RF = permute(RF,[2 1 3]); % Nt-by-Nelem-by-Nframes
RF = hilbert(RF);
RF = reshape(double(RF),[Nt*Nelem,Nframes]); 

disp('Applying DAS matrix')
% Apply delay and sum matrix:
IMG = full(M_DAS*RF);

disp('Reshaping image data array')
% Reshape image into an Nx-by-Ny-by-Nframes (axial-by-lateral) array:
IMG = reshape(IMG, [length(x) length(y) Nframes]);

%==========================================================================
% DEMODULATION AND LOG COMPRESSION
%==========================================================================
% Demodulation of the signals:
IMG = abs(IMG);

% Log compression:
IMG_max = max(IMG,[],[1,2]); % Maximum value (1-by-1-by-Nframes)
IMG = 20*log10(IMG./IMG_max);

end