function [sensor, sensor_weights, MB, max_dist] = ...
    define_sensor_MB(Grid, MB)
% =========================================================================
% DEFINE THE SENSOR: MBs and transducer record pressure
% input:    kgrid
%           grid_coordinates
%           folder 
%           frame
%           Geometry
% output:   sensor - mask of sensors
%           MB - struct with linear indexes of MBs in the sensor mask and 
%           indexes of recorded pressure lines (corresponding to MBs) in 
%           sensor_data
%           transducer - update of the transducer struct with same indexes
%           as MBs
% 
%
% =========================================================================

sensor.mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz);

% Put the microbubbles on the grid:
[MB.points, MB.nodes, MB.idx, idx_exclude] = ...
    voxelize_media_points(MB.points,Grid);

% Exclude microbubbles outside the grid:
MB.radii     (idx_exclude,:) = [];
MB.velocities(idx_exclude,:) = [];

% Compute pair-wise distance matrix:
dx = MB.points(:,1) - transpose(MB.points(:,1));
dy = MB.points(:,2) - transpose(MB.points(:,2));
dz = MB.points(:,3) - transpose(MB.points(:,3));

dist = sqrt(dx.^2 + dy.^2 + dz.^2);

% Maximum distance between pairs of microbubbles:
max_dist = max(dist, [], 'all'); 

% If no microbubbles present, set max_dist to zero:
if isempty(max_dist)
    max_dist = 0;
end

% Put sensors at the microbubbles
mask_only = false;
[sensor, sensor_weights] = update_sensor(sensor, MB.points, MB.idx, ...
    Grid, mask_only);

sensor.record={'p'};  

end
