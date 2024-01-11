function [position,isterminal,direction] = exitVesselFcn(~,y,grid)
% Function to identify a streamline exiting the vessel. Terminates the ODE
% solver.

% Get the indices of the nearest points in the vtu list:
vtuInd = get_vtu_indices(transpose(y),grid);

position = [vtuInd; vtuInd; vtuInd]; % The value that we want to be zero
isterminal = [1; 1; 1]; % Halt integration 
direction  = [0; 0; 0]; % The zero can be approached from either direction

end