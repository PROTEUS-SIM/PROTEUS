% This script creates the required files for running acoustic simulations
% on new VTU data from the flow simulation module. It performs the
% following steps:
%
% 1. Read a VTU file and convert it to MATLAB format using the vtkToolbox
%    written by Steffen Schuler, Karlsruhe Institute of Technology.
%    (https://github.com/KIT-IBT/vtkToolbox). Also add geometry specific
%    metadata.
% 2. Obtain an STL file from the VTU data if no STL file is already
%    available.
% 3. Create a PNG image for display in the main window of the simulator, if
%    no PNG is already available.
% 4. Save metadata of the geometry to be read by the graphical user
%    interface.
%
% Before running the script, create a new folder in the geometry_data
% folder in which the required flow geometry data can be stored. Add to 
% this folder:
% - The VTU file with the simulated flow data of the new flow geometry.
% - An STL file of the flow geometry (if available, otherwise, it can be
%   created with this script).
% - A PNG of the flow geometry (if available, otherwise, it can be created
%   with this script).
%
% Nathan Blanken, Guillaume Lajoinie, University of Twente, 2023

clear; clc

addpath('vtkToolbox/MATLAB')

geometryFolder = 'renal_tree';

% Source VTU file:
VTUfilename = 'renal_tree.vtu';

% If an STL file or PNG file is not already available, set createSTL or
% createPNG to true. NOTE: if the file with the filename already exists, it
% will be overwritten.
createSTL = false;
createPNG = false;

% Filenames of STL file and PNG file
STLfilename = 'maa.stl';
PNGfilename = 'renal_tree.png';

% When using an existing STL file, specify the length unit:
if createSTL == false
    STLunit = 1e-6; % Length unit of the STL file [m]
end

% Paths to the files:
STLfilepath = [geometryFolder filesep STLfilename];
PNGfilepath = [geometryFolder filesep PNGfilename];
VTUfilepath = [geometryFolder filesep VTUfilename];

% Destination .MAT file (do not modify):
VTUsavepath = [geometryFolder filesep 'vtu.mat'];

% This file will hold geometry properties to be read by the graphical user
% interface (do not modify):
GEOMETRYfilepath = [geometryFolder filesep 'GeometryProperties.mat'];

%--------------------------------------------------------------------------
% CONVERT VTU FILE TO MATLAB FORMAT
%--------------------------------------------------------------------------

% Read VTU data
disp('PROCESS VTU FILE')
verbose = true; % Display progress messages
vtuStruct = readVTK(VTUfilepath, verbose);

switch geometryFolder
    case 'renal_tree'
        vtuProperties.lengthUnit    = 1e-6;   % [m]
        vtuProperties.velocityUnit  = 1;      % [m/s]
        
        % Estimate of the maximum inlet diameter [m]. Provide an upper
        % bound to the maximum diameter:
        vtuProperties.inletDiameter = 0.6e-3;
        
        % Normal to the inlet pointing inwards (currently supported only
        % along one of the cartesian axes). This is an optional struct
        % field and can also be automatically detected through streamline
        % backpropagation:
        vtuProperties.inletNormal   = [0 0 1];
        
        % Field of cellData that contains the velocities:
        vtuProperties.velocityField = 'velocity_phy';
        
    case 'mouse_brain'
        vtuProperties.lengthUnit    = 1e-6;
        vtuProperties.velocityUnit  = 1e-3;
        vtuProperties.inletDiameter = 15e-6;
        vtuProperties.inletNormal   = [-1 0 0]; % Optional
        vtuProperties.velocityField = 'velocity_phy';
        
    case 'straight_pipe'
        vtuProperties.lengthUnit    = 1e-2;
        vtuProperties.velocityUnit  = 1e-2;
        vtuProperties.inletDiameter = 15e-3;
        vtuProperties.inletNormal   = [0 1 0]; % Optional
        vtuProperties.velocityField = 'velocity_phy';
        
    case 'pipe_2cm_Re5000'
        vtuProperties.lengthUnit    = 1e-2;
        vtuProperties.velocityUnit  = 1e-2;
        vtuProperties.inletDiameter = 20e-3;
        vtuProperties.inletNormal   = [1 0 0]; % Optional
        vtuProperties.velocityField = 'velocity_phy';
        
    otherwise
        error(['Unknown geometry. '...
            'Specify vtuProperties struct for this geometry.'])
end

disp('Saving output struct...')
save(VTUsavepath,'vtuStruct','-v7.3')
disp('Output struct saved.')

rmpath('vtkToolbox/MATLAB')

%--------------------------------------------------------------------------
% LOAD AN STL FILE OR GENERATE AN STL FILE FROM THE VTU FILE
%--------------------------------------------------------------------------

if createSTL == true
    % For large CFD models, keep only a subset of the VTU points containing
    % N_STL points to accelerate triangulation. These points are randomly
    % selected to avoid the risks of distortion due to regular subsampling.
    % Note that N_STL is not equal to the number of vertices in the STL
    % file as the STL file only contains points on the free surface of the
    % VTU file.
    N_STL = 1e6;

    % Generate STL file:
    disp('GENERATE STL FILE')
    TR = vtu_to_stl(vtuStruct, N_STL, STLfilepath);
else
    disp('LOAD STL FILE')
    TR = stlread(STLfilepath);
end

%--------------------------------------------------------------------------
% CREATE A PNG IMAGE FOR DISPLAY IN THE GUI MAIN WINDOW
%--------------------------------------------------------------------------
if createPNG == true
    disp('CREATE PNG')
    create_png(TR,PNGfilepath)
end

% Note: the PNGs for the example vasculatures were created with the Windows
% application Paint 3D.

%--------------------------------------------------------------------------
% SAVE GEOMETRY METADATA FOR USE IN THE GRAPHICAL USER INTERFACE
%--------------------------------------------------------------------------
disp('SAVE GUI GEOMETRY METADATA')

X = TR.Points(:,1)';
Y = TR.Points(:,2)';
Z = TR.Points(:,3)';

STLfile = STLfilename;

if createSTL == true
    STLunit = vtuProperties.lengthUnit;
end

% Embed the vessel geometry in the medium of the acoustic simulations:
EmbedVessel = true;

% Extreme points of the bounding box enclosing the geometry:
BoundingBox.Xmax = max(X)*STLunit; BoundingBox.Xmin = min(X)*STLunit;
BoundingBox.Ymax = max(Y)*STLunit; BoundingBox.Ymin = min(Y)*STLunit;
BoundingBox.Zmax = max(Z)*STLunit; BoundingBox.Zmin = min(Z)*STLunit;

% Default rotation of the geometry:
switch geometryFolder
    case 'renal_tree'
        Rotation = [0 0 -1; -1 0 0; 0 1 0];
    otherwise
        Rotation = eye(3);
end

% Default fraction of STL vertices to display in the GUI:
fraction = min(1e4/length(X),1);

Visualization.Image = PNGfilename;
Visualization.Fraction = fraction;

save(GEOMETRYfilepath,'STLfile','STLunit','EmbedVessel',...
    'BoundingBox','Rotation','Visualization','vtuProperties');

%--------------------------------------------------------------------------
% FUNCTIONS
%--------------------------------------------------------------------------

function TR = vtu_to_stl(vtuStruct, N_STL, savename)
%VTU_TO_STL converts a set of points from a VTU file to an STL file with
%surface mesh vertices.
%
% Nathan Blanken, Guillaume Lajoinie, University of Twente, 2023

points = vtuStruct.points;

% Keep only unique points:
disp('Discarding duplicate points ...')
points = unique(points,'rows');

N = size(points,1);   % Number of unique points in vtu model
N_STL = min(N,N_STL); % Number of points to keep

% Select random subset of vtu points:
disp('Selecting subset of points ...')
I = sort(randperm(N,N_STL));
points = points(I,:);

% Alpha shape and triangulation:
disp('Triangulation ...')
SHP = alphaShape(points);
TRI = alphaTriangulation(SHP);

% Extraction of free boundary facets:
disp('Free surface extraction ...')
[F,P] = freeBoundary(triangulation(TRI, points));
TR = triangulation(F, P);

% Generate the STL file:
disp('Writing STL file ...')
stlwrite(TR, savename);

end

function create_png(TR,PNGfilename)
% Plot the triangulation from an STL file and save it as a PNG image.

h = get(0); % Screen properties
W = 222;    % Figure width in pixels
H = 283;    % Figure height in pixels
fig = figure;

% Centre the figure on the screen:
fig.Position = [h.ScreenSize(3)/2-W/2 h.ScreenSize(4)/2-H/2 W H];

% Plot the STL mesh:
trisurf(TR,'FaceColor','r','edgecolor','r') 
axis equal
ax = gca;

% White background, axes not visible:
set(fig, 'color', 'w');   
set(ax, 'GridLineStyle','none');
set(ax, 'color', 'w');
set(ax, 'XColor', 'none','YColor','none','ZColor','none');

% Fill full figure with axes area:
ax.Position = [0 0 1 1 ];

print(gcf,'-dpng','-r600',PNGfilename)

end