function velocity = get_velocity(position, grid, velocities)

% Get the indices of the nearest points in the vtu list:
vtuInd = get_vtu_indices(position,grid);

% Get the velocity from the vtu velocity list:
velocity = zeros(size(position));
velocity(vtuInd>0,:) = velocities(vtuInd(vtuInd>0),:);

end