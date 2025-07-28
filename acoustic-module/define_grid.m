function pgrid = define_grid(SimulationParameters, Geometry)
%DEFINE_GRID returns a PROTEUS grid
% pgrid = DEFINE_GRID(SimulationParameters,Geometry) constructs a PROTEUS
% grid from the simulation settings structs SimulationParameters and
% Geometry.
%
% The PROTEUS grid is used throughout the PROTEUS toolbox. It is used to
% define the medium, source and sensor objects, and the k-Wave grid (an
% instance of the kWaveGrid class from the k-Wave toolbox).
%
% pgrid has the following fields:
% - x: a 1D array with the x coordinates of the grid
% - y: a 1D array with the y coordinates of the grid
% - z: a 1D array with the z coordinates of the grid
% - Nx: number of elements in x
% - Ny: number of elements in y
% - Nz: number of elements in z
% - dx: grid spacing along x
% - dy: grid spacing along y
% - dz: grid spacing along z
% - dt: time interval
% - full_size: size of the gridd including the PML [3×1 double]
% - PML: a struct with the fields:
%   - X_SIZE: thickness of the perfectly matched layer along x
%   - Y_SIZE: thickness of the perfectly matched layer along y
%   - Z_SIZE: thickness of the perfectly matched layer along z
%   - Alpha:  absorption within the perfectly matched layer
% - sensor_on_grid: boolean for on- or off-grid sensors
%
% DEFINE_GRID positions the grid such that all grid points fall within or
% on the domain boundaries.
%
% The PML size is chosen such that the total number of grid points in each
% direction has small prime factors. From the k-Wave User Manual:
% "The time to compute each FFT can be minimised by choosing the total 
% number of grid points in each direction (including the PML) to be a power
% of two, or to have small prime factors."
%
% Nathan Blanken, University of Twente, 2024

% Get the spacing between the grid points
dx = SimulationParameters.GridSize; % [m] 
dy = dx;                 
dz = dx;

% Get the domain boundaries:
D = Geometry.Domain;

% Set up integer grids:
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
if isfield(SimulationParameters,'MaxPrime')
    maxPrime = SimulationParameters.MaxPrime;
else
    maxPrime = 5; % Default maximum prime factor
end

% Minimum PML thickness:
if isfield(SimulationParameters,'PMLmin')
    PMLmin = SimulationParameters.PMLmin;
else
    PMLmin = 15; % Default minimum PML thickness
end

% Choose the size of the full grid (k-Wave grid and perfectly matched 
% layer) to have small prime factors:
Mx = optimize_grid_size(Nx, 2*PMLmin, maxPrime);
My = optimize_grid_size(Ny, 2*PMLmin, maxPrime);
Mz = optimize_grid_size(Nz, 2*PMLmin, maxPrime);

% Size of the perfectly matched layer (PML):
PML.X_SIZE = ceil((Mx-Nx)/2);
PML.Y_SIZE = ceil((My-Ny)/2);
PML.Z_SIZE = ceil((Mz-Nz)/2);

% Absorption within the perfectly matched layer in Nepers per grid point:
PML.Alpha = 2;

% Size of core grid:
Nx = Mx - 2*PML.X_SIZE;
Ny = My - 2*PML.Y_SIZE;
Nz = Mz - 2*PML.Z_SIZE;

% Set the time step:
dt = 1/SimulationParameters.SamplingRate;

% Compute the grid coordinate vectors:
pgrid.x = (X1:(X1+Nx-1))*dx;
pgrid.y = (Y1:(Y1+Ny-1))*dy;
pgrid.z = (Z1:(Z1+Nz-1))*dz;

pgrid.Nx = Nx;
pgrid.Ny = Ny;
pgrid.Nz = Nz;

pgrid.dx = dx;
pgrid.dy = dy;
pgrid.dz = dz;

pgrid.dt = dt;

% Size of the grid including PML:
pgrid.full_size = [Mx; My; Mz];

pgrid.PML = PML;

% Snap microbubbles to the grid or not:
pgrid.sensor_on_grid = SimulationParameters.SensorOnGrid;

end