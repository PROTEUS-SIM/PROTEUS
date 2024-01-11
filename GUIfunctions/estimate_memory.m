function [T_all, mem] = estimate_memory(Acquisition, Geometry, Medium, ...
    SimulationParameters, Transmit, beta_coeff_file)

% Compute the grid size:
c    = Medium.SpeedOfSound;
f0   = Transmit.CenterFrequency;
ppwl = SimulationParameters.PointsPerWavelength;

% Get the spacing between the grid points
dx = c/(f0*ppwl); % [m] 
dy = dx; dz = dx;
dt = 1/SimulationParameters.SamplingRate; % [s]

% Get the domain boundaries:
D = Geometry.Domain;

% Estimate the size of the k-Wave grid:
Nx = round((D.Xmax - D.Xmin)/dx);
Ny = round((D.Ymax - D.Ymin)/dy);
Nz = round((D.Zmax - D.Zmin)/dz);

% Estimate the simulation time step:
load(beta_coeff_file, 'beta_coeff');
t_step = 10^(beta_coeff(1) + beta_coeff(2) * log10(Nx*Ny*Nz));

% Approximate travel times:
d = norm(Geometry.BoundingBox.Diagonal);
tr(1) = D.Xmax/c;           % Transmit time [s]
tr(2) = D.Xmax/c + d/c;     % Transmit and interaction time [s]
tr(3) = D.Xmax/c*2;         % Transmit and receive time [s]

Nt = zeros(1,3); T = zeros(1,3);

for i = 1:3
    Nt(i) = floor(tr(i) / dt) + 1;  % Number of time steps  
    T(i) = t_step * Nt(i);          % Simulation time
end

NFrames = Acquisition.NumberOfFrames;
Ninter  = SimulationParameters.NumberOfInteractions;

T_all = T(1) + NFrames*(Ninter*T(2) + T(3));

% Estimate the number of sources in the transducer:
V = Geometry.Domain.TransducerSurface;
W = max(V(:,2)) - min(V(:,1));  % Width [m]
H = max(V(:,2)) - min(V(:,1));  % Height [m]
NSources = round(W/dy*H/dz);

% Estimate number of elements in the input signal:
Nt_source = round(length(Transmit.PressureSignal)...
    *SimulationParameters.SamplingRate/Transmit.SamplingRate);

% highest memory consumption is expected in 3rd itteration
A_max = 9;
B_max = 2;

% Input and output signals:
input  = NSources*Nt_source;
output = NSources;

% k-Wave manual, equation 4.1 (Version 1.1 ,August 27, 2016):
mem = ((13 + A_max)*Nx*Ny*Nz + (7 + B_max)*Nx*Ny*Nz/2)*4  + ...
    (input*8 + output*8);

% Memory in GB:
mem = mem/1024^3;

end

