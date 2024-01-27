function [IMG,z,x] = DAS_reconstruction(folder,filename_parameters)

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
Fs = SimulationParameters.SamplingRate; % Sampling rate (Hz)
t = (0:(Nt-1))/Fs;  % Time axis (s)

% Transducer properties:
p = Transducer.Pitch;
x_el = -p/2*(Nelem-1) + (0:(Nelem-1))*p; % Element positions (m)
focus = Transmit.LateralFocus;

% Reconstruction properties:
c = Medium.SpeedOfSound;           % Speed of sound in the medium [m/s]
f0 = Transmit.CenterFrequency;     % Centre frequency [Hz]
lambda = c/f0;                     % Wavelength [m]
pixelSize = lambda/5;

Domain = Geometry.Domain;
width = Domain.Ymax - Domain.Ymin; % Domain width (m)
depth = Domain.Xmax;               % Domain depth (m)
x = -width/2:pixelSize:width/2;    % Lateral coordinates (m)
z = 0:pixelSize:depth;             % Axial coordinates (m)

%==========================================================================
% COMPUTE TIME TO PEAK
%==========================================================================
% Compute the time to peak of the two-way pulse
IR = Transducer.ReceiveImpulseResponse;
V_ref = conv(Transmit.PressureSignal,IR)/Transducer.SamplingRate; % two-way
[~,I] = max(abs(hilbert(V_ref)));
timeToPeak = I/Transmit.SamplingRate;

% Compute the lens correction:
H = Transducer.ElementHeight;
F = Transducer.ElevationFocus;
if isfinite(abs(F))
    lensCorrection = sqrt((H/2).^2 + F^2)/c - F/c;
else
    lensCorrection = 0;
end
lensCorrection = 2*lensCorrection;

% Correction for the k-Wave staggered grid:
dt = 1/SimulationParameters.SamplingRate;
dx = SimulationParameters.GridSize;
if SimulationParameters.HybridSimulation
    kWaveCorrection = dx/(2*c) + dt;
else
    kWaveCorrection = dx/(2*c) + dt*3/2;
end

% Time with respect to the peak of the transmit pulse:
t = t - timeToPeak - lensCorrection + kWaveCorrection;

%==========================================================================
% TIME GAIN COMPENSATION (TGC)
%==========================================================================
att = Medium.AttenuationA*(f0*1e-6)^Medium.AttenuationB;
TGC = sqrt(t)/max(sqrt(t)).*10.^(att.*t.*c.*1e2./20./2); 
TGC(t<0) = 0;

RF = RF.*TGC;

%==========================================================================
% COMPUTE DAS MATRIX
%==========================================================================
M_DAS = compute_das_matrix(t, x, z, x_el, c, Fs, focus);

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
% Reshape image into an Nx-by-Ny-by-Nframes array:
IMG = reshape(IMG, [length(x) length(z) Nframes]);

%==========================================================================
% DEMODULATION AND LOG COMPRESSION
%==========================================================================
% Demodulation of the signals:
IMG = abs(IMG);

% Log compression:
IMG_max = max(IMG,[],[1,2]); % Maximum value (1-by-1-by-Nframes)
IMG = 20*log10(IMG./IMG_max);

end