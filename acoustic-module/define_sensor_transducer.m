function [sensor, sensor_weights] = define_sensor_transducer(...
    Transducer, Grid)
%DEFINE_SENSOR_TRANSDUCER Sensor mask and weights of the transducer
%integration points on the simulation grid.
%
% All integration points must lie on the grid. The PROTEUS convention is
% x axial (depth), y lateral, z elevation (height); a transducer or a grid
% defined in another orientation leaves points outside the grid, which is
% an error (rather than an empty or incomplete sensor mask).

Grid.sensor_on_grid = Transducer.OnGrid;

% Get number of transducer elements, number of integration points per
% element and number of dimensions:
[N_el,N_int,N_dim] = size(Transducer.integration_points);

N_points =  N_int*N_el;
points = reshape(Transducer.integration_points, N_points, N_dim);

% Get the indices of the nearest grid points:
[points, ~, points_idx, outside] = voxelize_media_points(points, Grid);

if any(outside)
    P = reshape(Transducer.integration_points, N_points, N_dim);
    error('define_sensor_transducer:pointsOutsideGrid', ...
        ['%d of %d transducer integration points lie outside the grid.\n' ...
        'Points: x %s, y %s, z %s mm. Grid: x %s, y %s, z %s mm.\n' ...
        'PROTEUS uses x axial (depth), y lateral, z elevation (height): ' ...
        'check that the transducer and the grid use this orientation.'], ...
        nnz(outside), N_points, span(P(:,1)), span(P(:,2)), span(P(:,3)), ...
        span(Grid.x), span(Grid.y), span(Grid.z))
end

% Distribute the point sensors over a subset of the simulation grid:

mask_only = false;
sensor.mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz, 'logical');

[sensor, sensor_weights] = update_sensor_fast(...
    sensor, points, points_idx, Grid, mask_only);

sensor.record = {'p'};

end

function s = span(v)
s = sprintf('[%.2f, %.2f]', min(v(:))*1e3, max(v(:))*1e3);
end
