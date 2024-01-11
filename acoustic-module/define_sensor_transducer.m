function [sensor, sensor_weights] = define_sensor_transducer(...
    Transducer, Grid)

Grid.sensor_on_grid = false;

% Get number of transducer elements, number of integration points per
% element and number of dimensions:
[N_el,N_int,N_dim] = size(Transducer.integration_points);

N_points =  N_int*N_el;
points = reshape(Transducer.integration_points, N_points, N_dim);

% Get the indices of the nearest grid points:
[points, ~, points_idx, ~] = voxelize_media_points(points, Grid);

% Distribute the point sensors over a subset of the simulation grid:

mask_only = false;
sensor.mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz, 'logical');
 
[sensor, sensor_weights] = update_sensor(...
    sensor, points, points_idx, Grid, mask_only);

sensor.record = {'p'};

end