function [sensor, sensor_weights] = update_sensor(...
    sensor, points, points_idx, Grid, mask_only)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SENSOR MASK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if Grid.sensor_on_grid
    
    % Put point sensors on the grid:
    mask_idx = unique(points_idx);
    sensor.mask(mask_idx) = 1;
    
    num_sparse_elements = length(points_idx);

else
    
    num_sparse_elements = 0;
        
    % Distribute the point sensors over a subset of the simulation grid:
    for n = 1:length(points_idx)
                      
        [~, mask_idx_local] = get_truncated_grid(...
            points(n,:), points_idx(n), Grid);

        sensor.mask(mask_idx_local) = true;
        
        num_sparse_elements = num_sparse_elements + length(mask_idx_local);
        
    end
    
end

if mask_only
    % Do not compute the sensor weights:
    sensor_weights = [];
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SENSOR WEIGHTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Compute the sensor weights (see Eq. 17 in Wise et al., J. Acoust. Soc. 
% Am., 146(1), 278-288, 2019):

mask_idx = find(sensor.mask);

% Preallocate indices and values for sparse matrix:
i = zeros(1,num_sparse_elements);
j = zeros(1,num_sparse_elements);
B = zeros(1,num_sparse_elements);

element_count = 1;

for n = 1:length(points_idx)
    
    if Grid.sensor_on_grid
        
        % Index of the grid point with the i-th sensor:
        mask_idx_local = points_idx(n);
        b = 1;
    else
        
        % Create a local grid around the point source
        [delta_grid, mask_idx_local] = get_truncated_grid(...
            points(n,:), points_idx(n), Grid);
               
        % Evaluate the delta function at the nodes:
        b = evaluate_delta_function(delta_grid, transpose(points(n,:)), ...
            [Grid.dx; Grid.dy; Grid.dz], Grid.full_size);
        
    end
    
    N = length(mask_idx_local);
    
    [~,sensor_data_idx,~] = ...
        intersect(mask_idx, mask_idx_local);
    
    i((element_count):(element_count+N-1)) = ones(1,N)*n;
    j((element_count):(element_count+N-1)) = transpose(sensor_data_idx);
    B((element_count):(element_count+N-1)) = b;
    
    element_count = element_count + N;

end

sensor_weights = sparse(i,j,B);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [local_grid, local_idx] = get_truncated_grid(...
    point, point_idx, Grid)
% Create a local grid around node, a subset of the global grid.

th = 4; % Truncation threshold

% Get the subscripts of the grid point closest to the i-th point source:
[i,j,k] = ind2sub([Grid.Nx, Grid.Ny, Grid.Nz],point_idx);

% Set up a local grid (do not expand grid in dimensions where the point is 
% on-grid):

if ~(point(1) == Grid.x(i))
    i = (i-th):(i+th);
end

if ~(point(2) == Grid.y(j))
    j = (j-th):(j+th);
end

if ~(point(3) == Grid.z(k))
    k = (k-th):(k+th);
end

[i, j, k] = ndgrid(i, j, k);
i = i(:)'; j = j(:)'; k = k(:)';

% Remove nodes outside the grid:
idx_exclude = ...
    (i < 1) | (j < 1) | (k < 1) | ...
    (i > Grid.Nx) | (j > Grid.Ny) | (k > Grid.Nz);

i(idx_exclude) = [];
j(idx_exclude) = [];
k(idx_exclude) = [];

% Convert subscript indices to linear coordinates of array:
local_idx = sub2ind([Grid.Nx Grid.Ny Grid.Nz] , i, j, k);

% Get the coordinates of the grid points:
x = Grid.x(i);
y = Grid.y(j);
z = Grid.z(k);

local_grid = [x; y; z];

end