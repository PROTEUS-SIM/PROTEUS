function [MP, MP_nodes, MB_idx, idx_exclude] = voxelize_media_points(...
    MP, Grid)

% Fix media points to the k-Wave grid
X = Grid.x;
Y = Grid.y;
Z = Grid.z;

% Remove points outside the grid:
idx_exclude = ...
    (MP(:,1) < min(X)) | (MP(:,2) < min(Y)) | (MP(:,3) < min(Z)) | ...
    (MP(:,1) > max(X)) | (MP(:,2) > max(Y)) | (MP(:,3) > max(Z));

MP(idx_exclude,:) = [];

% Fix media_points to grid:
MP_nodes(:,1) = round((MP(:,1) - min(X))/Grid.dx) + 1;
MP_nodes(:,2) = round((MP(:,2) - min(Y))/Grid.dy) + 1;
MP_nodes(:,3) = round((MP(:,3) - min(Z))/Grid.dz) + 1;

% Convert subscript indices to linear coordinates of array:
MB_idx = sub2ind([Grid.Nx, Grid.Ny, Grid.Nz] ,...
    MP_nodes(:,1), ...
    MP_nodes(:,2), ...
    MP_nodes(:,3));

end