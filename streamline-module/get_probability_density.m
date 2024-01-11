clear
clc
close all

%==========================================================================
% SETTINGS
%==========================================================================

geometryFolder = uigetdir(['..' filesep 'geometry_data']);

% Convolution kernel parameters (smoothing parameters):
conv_kernel_size = 21; % Convolution kernel size 
sigma = 3;             % Standard deviation


%==========================================================================
% LOAD DATA
%==========================================================================

% File with randomly sampled inlet points:
load([geometryFolder filesep 'inlet_points.mat'],'points')

% MATLAB file with VTU data of the flow simulation:
vtufilename = [geometryFolder filesep 'vtu.mat'];

% MATLAB file with VTU metadata:
GeometryPropertiesFilename = ...
    [geometryFolder filesep 'GeometryProperties.mat'];

load(GeometryPropertiesFilename,'vtuProperties')
[vtuStruct, Grid] = load_vessel_data(vtufilename, vtuProperties);

% Axis perpendicular to the inlet:
normal_axis = find(vtuProperties.inletNormal);

%==========================================================================
% CONVERT POINTS TO PROBABILITY DISTRIBUTION
%==========================================================================

% Get a two-dimensional histogram of the set of points:
[grid_points, density] = points_to_distribution(points, Grid, normal_axis);

%--------------------------------------------------------------------------
% FIGURE
%--------------------------------------------------------------------------
figure(1)
density_plot = squeeze(density);
density_plot(:, sum(density_plot,1) == 0) = [];
density_plot(sum(density_plot,2) == 0, :) = [];
imagesc(density_plot)
title('Original histogram')
%--------------------------------------------------------------------------

% Convert the histogram to a smooth probability density:
density = smooth_distribution(density, conv_kernel_size, sigma);

% Set the probability density to zero for points outside the vessel:
vtuIndGrid = get_vtu_indices(grid_points,Grid);
vesselMask = logical(reshape(vtuIndGrid, size(density)));
density = density.*vesselMask;     % Apply mask
density = density/sum(density(:)); % Renormalise

%--------------------------------------------------------------------------
% FIGURE
%--------------------------------------------------------------------------
figure(2)
imagesc(squeeze(density))
density_plot = squeeze(density);
density_plot(:, sum(density_plot,1) == 0) = [];
density_plot(sum(density_plot,2) == 0, :) = [];
imagesc(density_plot)
title('Smoothed histogram')
%--------------------------------------------------------------------------


%==========================================================================
% FILTER INLET POINTS
%==========================================================================

% Only keep points within in the vessel:
points     = grid_points(logical(vtuIndGrid),:);
density    = density(    logical(vtuIndGrid));
vtuIndGrid = vtuIndGrid( logical(vtuIndGrid));

% Only keep points with a nonzero inlet velocity:
points     = points( logical(vtuStruct.velocities(vtuIndGrid)),:);
density    = density(logical(vtuStruct.velocities(vtuIndGrid)));

% Only keep points with nonzero probability density:
points = points(logical(density),:);
density = density(logical(density));
density = density/sum(density(:)); % Renormalise

%--------------------------------------------------------------------------
% FIGURE
%--------------------------------------------------------------------------
figure(3)
scatter_size = sqrt(density);
scatter_size = scatter_size/max(scatter_size);
scatter3(points(:,1),points(:,2),points(:,3),scatter_size*100,'.')
title('Inlet points (dot area: probability density)')
xlabel('X (m)')
ylabel('Y (m)')
zlabel('Z (m)')
%--------------------------------------------------------------------------

% Size of the cells in the inlet plane:
cellsize = vtuStruct.cellsize;
cellsize(normal_axis) = 0;

%==========================================================================
% SAVE RESULTS
%==========================================================================
inlet.cellsize = cellsize;
inlet.points   = points;
inlet.density  = density;
save([geometryFolder filesep 'inlet.mat'],'inlet') % Do not modify