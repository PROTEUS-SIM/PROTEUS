function maxStep = get_step_size(...
    vtuStruct, velocityPercentile, stepTolerance)
%GET_STEP_SIZE Compute the maximum step size for streamline integration.
%
% Guillaume Lajoinie, Nathan Blanken, University of Twente, 2023

Ncells = size(vtuStruct.points,1);

% Get a sorted list of all normalized velocities in the vtu file:
velocityNorm = vecnorm(vtuStruct.velocities,2,2);
velocityNorm = sort(velocityNorm);

velocityReference = velocityNorm(floor(velocityPercentile*Ncells));
maxStep = vtuStruct.cellsize(1)/velocityReference*stepTolerance;

end