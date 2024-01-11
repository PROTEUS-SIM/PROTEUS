function position = draw_start_position(N,vesselStruct)
%DRAW_START_POSITION Draw random positions from a vessel.
%   position = DRAW_START_POSITION(N,vesselStruct) draws N
%   random positions from a vessel. The output array is N-by-3.
%   
%   vesselStruct should have the following fields:
%   - points: a set of points in R3 (M-by-3 array)
%   - cellsize: the size of the cell around each point (1-by-3 array)
%
%   If vesselStruct also has the field 'density', the probability of
%   drawing a point will be weighted.
%
%   Nathan Blanken, University of Twente, 2023


% Pick a random point:
if isfield(vesselStruct,'density')
    idxRand = randi_weighted(vesselStruct.density,N,1);
else
    idxRand = randi(size(vesselStruct.points,1),N,1);
end

position = vesselStruct.points(idxRand,:);

% Random position vector within a cell:
rand_addition = (rand(N,3) - 1/2).*vesselStruct.cellsize;
position = position + rand_addition;

end