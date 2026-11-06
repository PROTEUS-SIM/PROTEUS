function [Recon, Trans, Tx] = initialize_das_parameters(Medium, ...
    SimulationParameters, Transducer, Transmit, Geometry, Nelem, Nt)
%INITIALIZE_DAS_PARAMETERS Inputs of compute_das_matrix_general from the
%PROTEUS settings.
%
% [Recon, Trans, Tx] = INITIALIZE_DAS_PARAMETERS(Medium,
% SimulationParameters, Transducer, Transmit, Geometry, Nelem, Nt) returns
% the reconstruction, transducer and transmit structs used by
% compute_das_matrix_general for RF data with Nelem elements and Nt
% samples per element. Linear and curved arrays are supported.
%
% The time axis Recon.t is corrected for the time to peak of the two-way
% pulse, the lens delay and the k-Wave staggered grid, as in
% DAS_reconstruction.
%
% Rienk Zorgdrager, University of Twente, 2026

%==========================================================================
% RECONSTRUCTION GRID
%==========================================================================

% Time axis of the RF data:
Fs = SimulationParameters.SamplingRate; % Sampling rate (Hz)
t = (0:(Nt-1))/Fs;                      % Time axis (s)

c = Medium.SpeedOfSound;           % Speed of sound in the medium [m/s]
f0 = Transmit.CenterFrequency;     % Centre frequency [Hz]
lambda = c/f0;                     % Wavelength [m]
pixelSize = lambda/4;

% Image coordinates (PROTEUS convention): x axial, y lateral:
Domain = Geometry.Domain;
width = Domain.Ymax - Domain.Ymin;      % Domain width (m)
x = Domain.Xmin:pixelSize:Domain.Xmax;  % Axial coordinates (m)
y = -width/2:pixelSize:width/2;         % Lateral coordinates (m)

%==========================================================================
% TRANSDUCER
%==========================================================================
if ~ismember(Transducer.Configuration, {'Linear','Curved'})
    error('initialize_das_parameters:configuration', ...
        'Configuration ''%s'' is not supported.', Transducer.Configuration)
end

El = get_element_geometry(Transducer);
if numel(El.y) ~= Nelem
    error('initialize_das_parameters:elements', ...
        'The RF data has %d elements, the transducer %d.', ...
        Nelem, numel(El.y))
end

if strcmp(Transducer.Configuration,'Curved')
    alpha_th = pi/6;    % Threshold angle for apodization
else
    alpha_th = pi/3;
end

%==========================================================================
% TIME CORRECTIONS
%==========================================================================
% Time to peak of the two-way pulse:
IR = Transducer.ReceiveImpulseResponse;
V_ref = conv(Transmit.PressureSignal,IR)/Transducer.SamplingRate; % two-way
[~,I] = max(abs(hilbert(V_ref)));
timeToPeak = I/Transmit.SamplingRate;

% Lens correction:
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

% Time with respect to the moment the wave leaves the first element:
t = t - timeToPeak - lensCorrection + kWaveCorrection;

%==========================================================================
% STRUCTS
%==========================================================================
Recon = struct( ...
    'x', x, ...
    'y', y, ...
    'c', c, ...
    't', t, ...
    'Fs', Fs, ...
    'alpha_th', alpha_th, ...
    'apodization', 'cosine');

Trans = struct( ...
    'type', Transducer.Type, ...
    'configuration', Transducer.Configuration, ...
    'x_el', El.x', ...
    'y_el', El.y', ...
    'azimuth', El.theta', ...
    'center', El.Center, ...
    'radius', El.Radius);

if isfield(Transmit,'Apodization')
    apod = Transmit.Apodization;
else
    apod = ones(1,Nelem);
end

Tx = struct( ...
    'focus', Transmit.LateralFocus, ...
    'steer', deg2rad(Transmit.Angle), ...
    'apod', apod, ...
    'axis_delay', 0);

% The transmit model is built from the focus and the angle. Check that it
% matches the delays actually used (they differ for loaded delays, or for
% 'No delays' with a focus or angle):
if isfield(Transmit,'Delays') && numel(Transmit.Delays) == Nelem
    d = das_transmit_distance(El.x, El.y, Trans, Tx);
    mismatch = max(abs(d(:)'/c - Transmit.Delays(:)'));
    if mismatch > 1/(2*Fs)
        warning('initialize_das_parameters:delays', ...
            ['The transmit delays differ from the focus/angle model by ' ...
            'up to %.3g s: the reconstruction will be misaligned.'], mismatch)
    end
end

end
