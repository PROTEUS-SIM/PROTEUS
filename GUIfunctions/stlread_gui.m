function [X,Y,Z] = stlread_gui(STLfilepath,VOXELISATIONpath)
%STLREAD_GUI reads an STL file and returns the X, Y, Z coordinates of the
%vertices. For MATLAB version 2018b and later, the MATLAB function stlread
%reads the STL file. For earlier versions, the mesh voxelisation toolbox by
%Adam H. Aitkenhead is used for reading the STL file.
%
% Nathan Blanken, University of Twente, 2023

if verLessThan('matlab', '9.5')
    warning(['Upgrade to MATLAB R2018b or later for faster reading of '...
        'STL data.'])

    % Read STL file with mesh voxelisatin toolbox:
    addpath(VOXELISATIONpath)
    P = READ_stl(STLfilepath); % N-by-3-by-3
    rmpath(VOXELISATIONpath)

    % Get the vertices of the STL file:
    P = permute(P, [2 1 3]); % 3-by-N-by-3
    P = reshape(P, 3, []);   % 3-by-(N*3)
    P = permute(P, [2 1]);   % (N*3)-by-3
    P = unique( P, 'rows');  % Keep only unique vertices
else
    % Get the vertices of the STL file:
    P  = stlread(STLfilepath);
    P  = P.Points;
end

% Get X, Y, Z coordinates of the vertices:
X = P(:,1)';
Y = P(:,2)';
Z = P(:,3)';

end