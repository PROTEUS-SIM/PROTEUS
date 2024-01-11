function vtuInd = get_vtu_indices(points,Grid)
% Convert a list of points to list indices of the nearest points in a vtu
% file.
%
% INPUT:
% - points: list of points (Nx3 array)
% - Grid: grid properties as defined in load_vessel_data
%
% OUTPUT:
% - vtuInd: vtu list indices of the nearest points in the vtu file.
%
% Nathan Blanken, University of Twente, 2023

% Round off position to nearest grid point:
ix = round((points(:,1) - Grid.X(1))/Grid.dX) + 1;
iy = round((points(:,2) - Grid.Y(1))/Grid.dY) + 1;
iz = round((points(:,3) - Grid.Z(1))/Grid.dZ) + 1;

% Keep the grid point subscripts within limits:
ix_grid = min(Grid.NX, max(1,ix)); 
iy_grid = min(Grid.NY, max(1,iy)); 
iz_grid = min(Grid.NZ, max(1,iz)); 

% Identify the positions that fall outside the grid:
outsideGrid = (ix_grid ~= ix)|(iy_grid ~= iy)|(iz_grid ~= iz);

% Get the linear grid index of the nearest grid point:
ind = sub2ind([Grid.NX Grid.NY Grid.NZ], ix_grid, iy_grid, iz_grid);

% Get the corresponding index in the vtu velocity list:
vtuInd = full(Grid.vtu_indices(ind));

% Assign zero to points outside the grid:
vtuInd(outsideGrid) = 0;

end