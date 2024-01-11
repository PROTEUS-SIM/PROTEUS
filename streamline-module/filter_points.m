clear
clc
close all

% Folder containing the geometry data:
geometryFolder = ['..' filesep 'geometry_data'];
[vtufilename, pathname] = uigetfile([geometryFolder filesep '*vtu.mat'],...
    'Select vtu.mat file');

GeometryPropertiesFilename = 'GeometryProperties.mat';

% The maximum distance a streamline end point is allowed to be from any
% other end points is expressed as a fraction of the inlet diameter. This
% parameter is used to filter out isolated end points which will not be on
% the inlet surface. A lower factor should be chosen for a higher number of
% streamlines.
proximityFactor = 0.1;

% Load the end points of the backpropagation:
load(fullfile(pathname, 'backpropagation_points.mat'),...
    'points','t_end','Tmax','end_velocity');

%==========================================================================
% READ VESSEL DATA
%==========================================================================

% MATLAB file with VTU data of the flow simulation:
vtufilepath = fullfile(pathname, vtufilename);
GeometryPropertiesPath = fullfile(pathname, GeometryPropertiesFilename);

load(GeometryPropertiesPath,'vtuProperties')
[vtuStruct, Grid] = load_vessel_data(vtufilepath,vtuProperties);

%--------------------------------------------------------------------------
% Determine the normal to the inlet plane. The normal must be aligned with
% one of the cartesian axes. (METHOD 1: based on inlet velocity)
%--------------------------------------------------------------------------

% Find the cartesian axes that corresponds to the major flow vector
% component. This cartesian axes is aligned with the inlet normal provided
% the angle between the inlet flow and the inlet normal is not too large.
V = mean(-end_velocity); % Average velocity of the end points
[~, normal_axis] = max(abs(V));

inletNormal = zeros(1,3);
inletNormal(normal_axis) = sign(V(normal_axis));

% Check if the determined inlet normal corresponds to the inlet normal in
% the vtu properties struct:
if isfield(vtuProperties,'inletNormal') && ...
        ~isequal(inletNormal,vtuProperties.inletNormal)
    warning('Inlet normal discrepancy. Overwriting new inlet normal.')
    vtuProperties.inletNormal = inletNormal;
    save(GeometryPropertiesPath,'vtuProperties',"-append")
end

if ~isfield(vtuProperties,'inletNormal')
    vtuProperties.inletNormal = inletNormal;
    save(GeometryPropertiesPath,'vtuProperties',"-append")
end

%==========================================================================
% FILTER INLET POINTS
%==========================================================================

%--------------------------------------------------------------------------
% Only keep end points of streamlines that have terminated before the
% maximum integration time. These streamlines are most likely to have
% reached the inlet. Streamlines will terminate just outside the inlet. 
% Move points back into the vessel by half a grid spacing.
%--------------------------------------------------------------------------
points = points(t_end<Tmax,:);
points = points + 1/2*vtuStruct.cellsize.*vtuProperties.inletNormal;

%--------------------------------------------------------------------------
% Remove points not inside the vessel.
%--------------------------------------------------------------------------
vtuInd = get_vtu_indices(points,Grid);
points(vtuInd==0,:) = [];

%--------------------------------------------------------------------------
% Remove isolated points and remove points that are too far from the
% centroid of all other points.
%--------------------------------------------------------------------------
maxDistance = vtuProperties.inletDiameter*proximityFactor;
points = filter_points_proximity(points, maxDistance);
distance = vecnorm((points - mean(points)),2,2);
points(distance > 2*vtuProperties.inletDiameter,:) = [];

%--------------------------------------------------------------------------
% Determine the normal to the inlet plane. The normal must be aligned with
% one of the cartesian axes. (METHOD 2: based on point spread)
%--------------------------------------------------------------------------

[~, normal_axis] = min(std(points));

inletNormal = zeros(1,3);
inletNormal(normal_axis) = sign(V(normal_axis));

% Check if the determined inlet normal corresponds to the inlet normal in
% the vtu properties struct:
if ~isequal(inletNormal,vtuProperties.inletNormal)
    warning('Inlet normal discrepancy. Overwriting new inlet normal.')
    vtuProperties.inletNormal = inletNormal;
    save(GeometryPropertiesPath,'vtuProperties',"-append")
end

%--------------------------------------------------------------------------
% Remove points too far from the inlet plane
%--------------------------------------------------------------------------
% Round points to nearest grid point along the normal axis:
vtuInd = get_vtu_indices(points,Grid);
points(:,normal_axis) = vtuStruct.points(vtuInd,normal_axis);

% Estimate the coordinate of the inlet plane based on the most frequently
% occuring coordinate along the normal axis:
inlet_coordinate = mode(points(:,normal_axis));

% Compute the distance of each point to the inlet plane:
distance = abs(points(:,normal_axis) - inlet_coordinate);

% Remove points to far from the inlet plane:
points(distance>(vtuStruct.cellsize(normal_axis)/2),:) = [];

%--------------------------------------------------------------------------
% Remove points too far from the centroid of the inlet
%--------------------------------------------------------------------------

% Remove points that are in the infinite inlet plane but not in the inlet
% (subset of the inlet plane):
distance = vecnorm((points - mean(points)),2,2);
points(distance > vtuProperties.inletDiameter,:) = []; 

%==========================================================================
% PLOT AND SAVE RESULTS
%==========================================================================

figure();
plot3(points(:,1),points(:,2),points(:,3),'.');
xlabel('X (m)')
ylabel('Z (m)')
zlabel('Z (m)')
title('Streamline end points')

save(fullfile(pathname, 'inlet_points.mat'),'points');