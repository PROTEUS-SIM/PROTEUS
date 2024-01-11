function points = filter_points_proximity(points, proximity)
% Removes points from a list of points that are not in close proximity to
% any other point.
% 
% INPUT
% - points: list of points (Mx3 array)
% - proximity: maximum distance of a given point to all other points:
%
% OUTPUT:
% - points: the filtered list of points
%
% Nathan Blanken, University of Twente, 2023

M = size(points,1);

% Compute pairwise distance matrix:
points1(:,1,:) = points; % (Mx1x3 array)
points2(1,:,:) = points; % (1xMx3 array)
D = vecnorm(points1-points2,2,3); % Pairwise distance matrix (MxM)

% Compute the minimum of each point to other points (NaN on the diagonal
% excludes distance of each point to itself):
distance = min(D + diag(nan(M,1),0));

% Exclude points removed too far from other points:
points(distance>proximity,:) = [];

end