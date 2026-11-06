function [sensor, sensor_weights] = update_sensor_fast(...
    sensor, points, points_idx, Grid, mask_only)
%UPDATE_SENSOR_FAST computes a sensor mask and a weights matrix that
%specifies the relation between sensor points on the grid and sensor points
%in continuous space.
%
% [SENSOR, SENSOR_WEIGHTS] = UPDATE_SENSOR_FAST(SENSOR, POINTS, POINTS_IDX,
% GRID, MASK_ONLY) converts a continuous sensor representation defined by
% POINTS into a grid-based source representation.
%
% SENSOR_WEIGHTS is a sparse matrix that contains the weights relating the
% discrete sensor points and the continuous sensor points.
%
% If the input sensor mask is not empty, sensor points are added to the
% mask.
%
% If no SENSOR_WEIGHTS matrix is required, setting MASK_ONLY = true, speeds
% up computation.
%
% See Section V.-E. of PROTEUS Part-I
% See Wise et al., J. Acoust. Soc. Am., 146(1), 278-288, 2019)
%
% See also: update_sensor
%
% Nathan Blanken, University of Twente, 2025

Npoints = size(points,1);

%==========================================================================
% ON-GRID SENSORS
%==========================================================================

if Grid.sensor_on_grid
    
    % Put point sensors on the grid:
    mask_idx = unique(points_idx);
    sensor.mask(mask_idx) = 1;

    if mask_only
        % Do not compute the sensor weights:
        sensor_weights = [];
        return
    end
    
    i = transpose(1:Npoints);
    [~,j] = ismember(points_idx,mask_idx);
    B = ones(Npoints,1);

    % Create a sparse matrix relating sensor points in the continuous space
    % to sensor grid points:

    sensor_weights = sparse(i,j,B);
    return
end

%==========================================================================
% OFF-GRID SENSORS
%==========================================================================

% Truncated grid size
if isfield(Grid,'threshold')
    th = Grid.threshold; % Truncation threshold
else
    th = 4; % Default truncation threshold
end
N = th*2 + 1; % Length of the cubical subgrid in number of grid points

%--------------------------------------------------------------------------
% Memory requirement estimate for computing sensor mask
%--------------------------------------------------------------------------

% Assume a RAM availability of 2 GiB (conservative estimate). Make this
% value system dependent in a future version:
maxMemory = 2*1024^3;

% Check if the variables I, J, K, and mask_idx_local fit in RAM. Each of
% these variables will assigned a size of at most N^3*Npoints elements.
bytesPerDouble = 8;
memoryBytes = 4*N^3*Npoints*bytesPerDouble;

% Revert to the slower for-loop, if data does not fit in RAM:
if memoryBytes > maxMemory
    [sensor, sensor_weights] = update_sensor(...
        sensor, points, points_idx, Grid, mask_only);
    return
end

%--------------------------------------------------------------------------
% Set up a truncated grid for each sensor point
%--------------------------------------------------------------------------

% Get the subscripts of the grid point closest to the points sensors:
[I,J,K] = ind2sub([Grid.Nx, Grid.Ny, Grid.Nz],points_idx);

I = transpose(I);
J = transpose(J);
K = transpose(K);

% Find points that are on grid in any of the spatial dimensions:
ongrid = zeros(size(points),'logical');
ongrid(:,1) = points(:,1) == transpose(Grid.x(I));
ongrid(:,2) = points(:,2) == transpose(Grid.y(J));
ongrid(:,3) = points(:,3) == transpose(Grid.z(K));
ongrid = transpose(ongrid);

% For each point, set up a local grid:
[i, j, k] = ndgrid(-th:th, -th:th, -th:th);

I = I + i(:);
J = J + j(:);
K = K + k(:);

%==========================================================================
% EXCLUDE UNDEFINED AND UNNECESSARY GRID POINTS
%==========================================================================

% Remove nodes outside the grid:
include = ...
    (I >= 1) & (J >= 1) & (K >= 1) & ...
    (I <= Grid.Nx) & (J <= Grid.Ny) & (K <= Grid.Nz);

include = reshape(include,[N,N,N,Npoints]);

i_eliminate = [1:th (th+2):(2*th+1)];

% Cut out x dimension
include(i_eliminate,:,:,ongrid(1,:)) = false;

% Cut out y dimension
include(:,i_eliminate,:,ongrid(2,:)) = false;

% Cut out z dimension
include(:,:,i_eliminate,ongrid(3,:)) = false;

include = reshape(include,[N^3,Npoints]);

include = include(:);
I = I(include);
J = J(include);
K = K(include);

%==========================================================================
% SENSOR MASK
%==========================================================================

mask_idx_local = sub2ind([Grid.Nx, Grid.Ny, Grid.Nz],I,J,K);
mask_idx = unique(mask_idx_local);

sensor.mask(mask_idx) = true;

if mask_only
    % Do not compute the sensor weights:
    sensor_weights = [];
    return
end

%==========================================================================
% SENSOR WEIGHTS
%==========================================================================

% Compute the sensor weights (see Eq. 17 in Wise et al., J. Acoust. Soc. 
% Am., 146(1), 278-288, 2019):

%--------------------------------------------------------------------------
% Memory requirement estimate for computing sensor weights
%--------------------------------------------------------------------------

% Number of nonzero elements in the sensor_weights matrix:
M = sum(include);

% Variables with M elements: I,J,K,i,j,mask_idx
% Variables with M*3 elements: delta_grid, points(:,i)
% Variables with M*3 elements in evaluate_delta_function:
% b_odd, b_even, b

memoryBytes = (6 + 2*3 + 3*3)*M*bytesPerDouble;

% Revert to the slower for-loop, if data does not fit on RAM:
if memoryBytes > maxMemory
    [sensor, sensor_weights] = update_sensor(...
        sensor, points, points_idx, Grid, mask_only);
    return
end

%--------------------------------------------------------------------------
% Get truncated grid
%--------------------------------------------------------------------------
I = transpose(I);
J = transpose(J);
K = transpose(K);
delta_grid = [Grid.x(I); Grid.y(J); Grid.z(K)];

i = repmat((1:Npoints),N^3,1);
i = i(include);

[~,j] = ismember(mask_idx_local,mask_idx);

% Evaluate the delta function at the nodes:
B = evaluate_delta_function(delta_grid, transpose(points(i,:)), ...
    [Grid.dx; Grid.dy; Grid.dz], Grid.full_size);

% Create a sparse matrix relating sensor points in the continuous space to
% sensor grid points:

sensor_weights = sparse(i,j,B);

end