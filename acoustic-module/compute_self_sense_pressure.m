function self_sense_pressure = compute_self_sense_pressure(...
    kgrid, Grid, MB_idx, MB_points, mass_source, ...
    medium, NX, run_param)

N_MB = length(MB_idx);

self_sense_pressure = zeros(N_MB,kgrid.Nt);

% Set the size of the perfectly matched layer (PML)
PML.X_SIZE = 10;            % [grid points]
PML.Y_SIZE = 10;            % [grid points]
PML.Z_SIZE = 10;            % [grid points]
PML.Alpha = 2;

run_param_local = run_param;
run_param_local.PML = PML;

% Properties of the new k-Wave grid:
dx = Grid.dx;
dy = Grid.dy;
dz = Grid.dz;
dt = Grid.dt;

% Choose Nx such that the total grid size has small prime factors (see
% define_PML):
maxPrime = 5;
NX = optimize_grid_size(NX, 2*PML.X_SIZE, maxPrime);
NX = NX-2*PML.X_SIZE;

NY = NX; % [voxels]
NZ = NX; % [voxels]

% Inherited properties of each local grid from the global grid:
Grid_local.dt             = Grid.dt;
Grid_local.full_size      = Grid.full_size;
Grid_local.sensor_on_grid = Grid.sensor_on_grid;

for MB_number = 1:N_MB

    disp(['Computing self-sense pressure bubble ' num2str(MB_number) ...
    ' out of ' num2str(N_MB) ' ...'])

    % Subscripts of the microbubble in the old grid: 
    [ax,ay,az] = ind2sub([Grid.Nx, Grid.Ny, Grid.Nz],MB_idx(MB_number));

    % Subscripts of the microbubble in the new grid:
    bx = floor(NX/2) + 1;
    by = floor(NY/2) + 1;
    bz = floor(NZ/2) + 1;

    % Subscripts for slicing the old grid:
    i = (1:NX); I = i + ax - bx;
    j = (1:NY); J = j + ay - by;
    k = (1:NZ); K = k + az - bz;
    
    % Remove subscripts outside the old grid:
    i(I<1|I>Grid.Nx) = [];  I(I<1|I>Grid.Nx) = []; 
    j(J<1|J>Grid.Ny) = [];  J(J<1|J>Grid.Ny) = []; 
    k(K<1|K>Grid.Nz) = [];  K(K<1|K>Grid.Nz) = []; 
    
    bx = bx - i(1) + 1; Nx = length(i);
    by = by - j(1) + 1; Ny = length(j);
    bz = bz - k(1) + 1; Nz = length(k);

    % Linear index in the new grid:
    MB_idx_local = sub2ind([Nx,Ny,Nz],bx,by,bz);

    % Assign the new k-Wave grid:
    kgrid_local = kWaveGrid(Nx, dx, Ny, dy, Nz, dz);
    kgrid_local.setTime(kgrid.Nt, dt);

    % Properties of the local grid:
    Grid_local.x = Grid.x(I); Grid_local.Nx = Nx; Grid_local.dx = dx;
    Grid_local.y = Grid.y(J); Grid_local.Ny = Ny; Grid_local.dy = dy;
    Grid_local.z = Grid.z(K); Grid_local.Nz = Nz; Grid_local.dz = dz;

    % Define the properties of the propagation medium
    medium_local.sound_speed  = medium.sound_speed( I, J, K);
    medium_local.density      = medium.density(     I, J, K);
    medium_local.BonA         = medium.BonA(        I, J, K);
    medium_local.alpha_coeff  = medium.alpha_coeff( I, J, K);
    medium_local.alpha_power  = medium.alpha_power;

    % Define sensor
    sensor_local.mask = zeros(Nx,Ny,Nz,'logical');
    mask_only = false;
    [sensor_local, sensor_weights] = update_sensor(sensor_local, ...
        MB_points(MB_number,:), MB_idx_local, Grid_local, mask_only);
    sensor_local.record = {'p'};
    
    sensor_mask_idx = find(sensor_local.mask);

    % Define source   
    source_local = update_source([], mass_source(MB_number,:), ...
    transpose(sensor_weights), sensor_mask_idx, Grid_local, medium_local);

    % Run the local, single-bubble simulation:
    sensor_data = run_simulation(run_param_local, kgrid_local, ...
        medium_local, source_local, sensor_local);
    
    sensed_p = sensor_weights*double(sensor_data.p);
    sensed_p = cast(full(sensed_p),class(sensor_data.p));
    
    self_sense_pressure(MB_number,:) = sensed_p;

end

end
