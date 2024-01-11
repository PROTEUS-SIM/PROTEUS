function [grid_coordinates, count] = ...
    points_to_distribution(points, Grid, normal_axis)
%POINTS_TO_DISTRIBUTION Two-dimensional histogram of a set of
%   three-dimensional points on a two-dimensional plane.
%   [grid_coordinates, count] = POINTS_TO_DISTRIBUTION(points, Grid,
%   normal_axis) returns the three-dimensional coordinates of the bin
%   centers of a two-dimensional histogram and the corresponding count of
%   points within each bin. points is a M-by-3 array, Grid contains the
%   grid properties of the three-dimensional grid as defined in 
%   load_vessel_data, the normal axis (1,2, or 3) is perpendicular to the 
%   histogram plane.
%
%   Nathan Blanken, University of Twente, 2023

% Get 3D grid cell centers and boundaries:
X = Grid.X; Xedges = [Grid.X (Grid.X(end) + Grid.dX)] - Grid.dX/2;
Y = Grid.Y; Yedges = [Grid.Y (Grid.Y(end) + Grid.dY)] - Grid.dY/2;
Z = Grid.Z; Zedges = [Grid.Z (Grid.Z(end) + Grid.dZ)] - Grid.dZ/2;

% Get the coordinate of the plane along the axis normal to the plane:
normal_coordinate = mean(points(:,normal_axis));

% Compute the cell centers of the 2D grid and the cell boundaries:
switch normal_axis
    case 1
        i = round((normal_coordinate - Grid.X(1))/Grid.dX) + 1;
        X = Grid.X(i);
        edges1 = Yedges;
        edges2 = Zedges;
    case 2
        i = round((normal_coordinate - Grid.Y(1))/Grid.dY) + 1;
        Y = Grid.Y(i);
        edges1 = Xedges;
        edges2 = Zedges;
    case 3
        i = round((normal_coordinate - Grid.Z(1))/Grid.dZ) + 1;
        Z = Grid.Z(i);
        edges1 = Xedges;
        edges2 = Yedges;
end

[Xmesh, Ymesh, Zmesh] = ndgrid(X, Y, Z);
grid_coordinates = [Xmesh(:) Ymesh(:) Zmesh(:)];

% Remove the singleton dimension:
points2D = points;
points2D(:,normal_axis) = [];

% Compute the count of each point within each 2D cell:
count    = zeros(size(Xmesh));
count(:) = histcounts2(points2D(:,1),points2D(:,2),edges1,edges2);


end