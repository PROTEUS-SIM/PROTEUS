function [kgrid, Grid] = define_grid(SimulationParameters, Geometry)
% =========================================================================
% DEFINE THE K-WAVE GRID
% input:    SimulationParameters
%           Geometry
%           Transducer
% output:   kgrid - k-space grid
%           grid_coordinates: struct with fields:
%           - x:     the axial coordinates of the grid
%           - y:   the lateral coordinates of the grid
%           - z: the elevation coordinates of the grid
%           PML: perfectly matched layer, struct with fields:
%           - X_SIZE
%           - Y_SIZE
%           - Z_SIZE
%           - Alpha
%
% Position the grid such that all grid points fall within or on the domain 
% boundaries.
%
% The PML size is chosen such that the total number of grid points in each
% direction has small prime factors.
%
% From the k-Wave User Manual:
% "The time to compute each FFT can be minimised by choosing the total 
% number of grid points in each direction (including the PML) to be a power
% of two, or to have small prime factors."
% =========================================================================

% Get the spacing between the grid points
dx = SimulationParameters.GridSize; % [m] 
dy = dx;                 
dz = dx;

% Get the domain boundaries:
D = Geometry.Domain;

% Set up (1/2-integer shifted) integer grids:
X1 =  ceil(D.Xmin/dx);
X2 = floor(D.Xmax/dx);

Y1 =  ceil(D.Ymin/dy);
Y2 = floor(D.Ymax/dy);

Z1 =  ceil(D.Zmin/dz);
Z2 = floor(D.Zmax/dz);

% Size of the k-Wave grid:
Nx = X2 - X1 + 1;
Ny = Y2 - Y1 + 1;
Nz = Z2 - Z1 + 1;

% Largest allowable prime factor in full grid size:
maxPrime = 5; 

% Minimum PML thickness:
PML_min = 15;

% Choose the size of the full grid (k-Wave grid and perfectly matched 
% layer) to have small prime factors:
Mx = optimize_grid_size(Nx, 2*PML_min, maxPrime);
My = optimize_grid_size(Ny, 2*PML_min, maxPrime);
Mz = optimize_grid_size(Nz, 2*PML_min, maxPrime);

% Size of the perfectly matched layer (PML):
PML.X_SIZE = ceil((Mx-Nx)/2);
PML.Y_SIZE = ceil((My-Ny)/2);
PML.Z_SIZE = ceil((Mz-Nz)/2);
PML.Alpha = 2;

Nx = Mx - 2*PML.X_SIZE;
Ny = My - 2*PML.Y_SIZE;
Nz = Mz - 2*PML.Z_SIZE;

% Create the k-Wave grid
kgrid = kWaveGrid(Nx, dx, Ny, dy, Nz, dz);

% Set the time step:
dt = 1/SimulationParameters.SamplingRate;
kgrid.dt = dt;

% Compute the grid coordinate vectors:
Grid.x = (X1:(X1+Nx-1))*dx;
Grid.y = (Y1:(Y1+Ny-1))*dy;
Grid.z = (Z1:(Z1+Nz-1))*dz;

Grid.Nx = Nx; Grid.dx = dx;
Grid.Ny = Ny; Grid.dy = dy;
Grid.Nz = Nz; Grid.dz = dz;

Grid.dt = dt;

% Size of the grid including PML:
Grid.full_size = [...
    Nx + PML.X_SIZE*2; ...
    Ny + PML.Y_SIZE*2; ...
    Nz + PML.Z_SIZE*2];

Grid.PML = PML;

% Snap microbubbles to the grid or not:
Grid.sensor_on_grid = SimulationParameters.SensorOnGrid;

end