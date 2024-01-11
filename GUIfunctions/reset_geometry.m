function Geometry = reset_geometry(Geometry,PATHS)

% Assign the renal tree folder if no geometry folder assigned:
if ~isfield(Geometry,'Folder')
    Geometry.Folder = 'renal_tree';
end

% Full path to the geometry data:
geometry_path = [PATHS.GeometriesPath filesep Geometry.Folder];

GeometryProperties = load(...
    [geometry_path filesep 'GeometryProperties.mat']);

Geometry.STLfile    = GeometryProperties.STLfile;
Geometry.STLunit    = GeometryProperties.STLunit; % STL unit length [m]

% Embed the vessel in the medium (assign vessel material properties to the
% voxels within the mesh):
Geometry.EmbedVessel = GeometryProperties.EmbedVessel;

% Bounding box of the vessel tree [m]:
BB = GeometryProperties.BoundingBox;

% Rotation matrix for the vessel tree and the microbubbles:
Geometry.Rotation = GeometryProperties.Rotation;

% Auto compute simulation domain:
Geometry.Domain.Manual = false;


% PROPERTIES FOR VISUALIZATION IN THE GUI:
% Visualization.Image:          Image to show in the main window
% Visualization.Fraction:       Fraction of STL vertices to show in plot

Geometry.Visualization = GeometryProperties.Visualization;

Geometry.BoundingBox.Center   = [(BB.Xmax + BB.Xmin)/2;... 
                                 (BB.Ymax + BB.Ymin)/2;...
                                 (BB.Zmax + BB.Zmin)/2];   
                           
Geometry.BoundingBox.Diagonal = [BB.Xmax - BB.Xmin;... 
                                 BB.Ymax - BB.Ymin;...
                                 BB.Zmax - BB.Zmin];

% Depth of vessel tree from transducer surface [m]
Geometry.startDepth  = 25e-3;                    


% PROPERTIES FOR VISUALIZATION IN THE GUI:

% Show the transducer and beam in plot:
Geometry.Visualization.ShowTransducer = 1;
Geometry.Visualization.ShowBeam       = 0;
Geometry.Visualization.ShowDomain     = 1;


end