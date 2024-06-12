function Geometry = compute_simulation_domain(...
    Geometry, Transducer, Transmit)
% Compute the required simulation domain. The simulation domain should
% capture the beam up to the maximum depth of the vessel tree.

% For RCA transducers only use the first half of the elements, representing
% the columns:
if isfield(Transducer,'Configuration') && ...
        strcmp(Transducer.Configuration,'RCA')
    N = Transducer.NumberOfElements;
    if mod(N,2)
        error('Number of elements in RCA must be even.')
    else
        Transducer.NumberOfElements = N/2;
    end
end

% Add the depth of the rotated bounding box to the start depth:
startDepth = Geometry.startDepth;
endDepth   = compute_end_depth(Geometry);

% Compute the vertices of the transducer surface and its projection on the
% back surface of the domain:
TransducerSurface = compute_transducer_vertices(Transducer);

Domain = Geometry.Domain;

% The object V is the set of points that should be included by the
% simulation domain:
if Domain.Manual
    V = TransducerSurface;
else
    TransducerProjection = compute_transducer_projection(...
        Transducer, Transmit, endDepth);
    V = [TransducerSurface; TransducerProjection];
end   

% Compute the domain boundary values, with a margin:

Vmax = max(V) + Domain.Margin;
Vmin = min(V) - Domain.Margin;

Xmax = Vmax(1); Ymax = Vmax(2); Zmax = Vmax(3);
Xmin = Vmin(1); Ymin = Vmin(2); Zmin = Vmin(3);

if Domain.Manual
    Xmin = min(Domain.Xmin, Xmin); Xmax = max(Domain.Xmax, Xmax);
    Ymin = min(Domain.Ymin, Ymin); Ymax = max(Domain.Ymax, Ymax);
    Zmin = min(Domain.Zmin, Zmin); Zmax = max(Domain.Zmax, Zmax);

    % Recompute the vertices of the projection on the back surface of the 
    % domain:
    TransducerProjection = compute_transducer_projection(...
        Transducer, Transmit, Xmax);
end

% Compute the vertices of the domain:
X = [Xmin Xmin Xmin Xmin Xmax Xmax Xmax Xmax];
Y = [Ymax Ymax Ymin Ymin Ymax Ymax Ymin Ymin];
Z = [Zmax Zmin Zmin Zmax Zmax Zmin Zmin Zmax];

% Store the transducer surface vertices, the projection vertices, the
% domain boundary values, and the domain vertices in a struct:

Domain.TransducerSurface     = TransducerSurface;
Domain.TransducerProjection  = TransducerProjection;

Domain.Xmax = Xmax; Domain.Ymax = Ymax; Domain.Zmax = Zmax;
Domain.Xmin = Xmin; Domain.Ymin = Ymin; Domain.Zmin = Zmin;

Domain.Vertices = transpose([X; Y; Z]);

% Add the Domain struct to the Geometry struct:
Geometry.Domain = Domain;

% Compute the centre of the rotated bounding box:
Geometry.Center = [(startDepth + endDepth)/2; 0; 0] ;


end

function TRANS_PROJECTION = ...
    compute_transducer_projection(Transducer, Transmit, d)
% Compute the vertices of the projection of the transducer surface on a
% parallel surface at a distance d from the transducer.
%
% The projection is defined as the intersection of two projections:
%
% PROJECTION 1: projection of the transducer surface through the elevation
% focus line onto the parallel surface (pinhole projection).
%
% Elevation focus line: x = f_e, z = 0
%
% PROJECTION 2: projection of the transducer surface through the lateral 
% focus line onto the parallel surface (pinhole projection).
%
% Lateral focus line: x = f_x, y = f_y
%
% INPUT:
% - Transducer: struct holding the transducer dimensions and the elevation
%   focus.
% - Transmit: struct holding the lateral focus distance and the transmit
%   angle.
%
% OUTPUT:
% - TRANS_SURFACE: Vertices of the transducer surface (4x3)
% - TRANS_PROJECTION: Vertices of the transducer projection (4x3)
%
% Nathan Blanken, University of Twente, 2022

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRANSDUCER AND BEAM PROPERTIES
p       = Transducer.Pitch;                 % [m]
w       = Transducer.ElementWidth;          % [m]
N       = Transducer.NumberOfElements;
f_e     = Transducer.ElevationFocus;        % [m]

f_l     = Transmit.LateralFocus;            % [m]
theta   = Transmit.Angle;                   % [deg]

% Compute transducer width and height:
W = p*(N-1) + w;                          	% [m]
H = Transducer.ElementHeight;               % [m]

% For custom transducer, no beam approximation can be computed. Return the
% transducer surface translated by the projection distance.
if isfield(Transducer,'Configuration') && ...
        strcmp(Transducer.Configuration,'Custom')
    TRANS_PROJECTION = compute_transducer_vertices(Transducer);
    TRANS_PROJECTION(:,1) = d;
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROJECTION VERTICES

% PROJECTION 1: projection through the elevation focus line.
zt =  H/2*(1-d/f_e);    % Top line
zb = -H/2*(1-d/f_e);    % Bottom line

% PROJECTION 2: projection through the lateral focus line.
if abs(f_l) < Inf
    % Focused beam:
    
    fx = f_l*cosd(theta);           % Axial focus coordinate
    fy = f_l*sind(theta);           % Lateral focus coordinate

    yl = -W/2*(1-d/fx) + d*fy/fx;   % Left line
    yr =  W/2*(1-d/fx) + d*fy/fx;   % Right line

else
    % Unfocused transducer:
    yl = -W/2 + d*sind(theta);      % Left line
    yr =  W/2 + d*sind(theta);      % Right line

end

% INTERSECTION OF THE TWO PROJECTIONS:
Xp = [d d d d];
Yp = [yr yl yl yr];
Zp = [zt zt zb zb];

TRANS_PROJECTION = transpose([Xp; Yp; Zp]);

end

function TRANS_SURFACE = compute_transducer_vertices(Transducer)
% Compute the vertices of the rectangular surface of a transducer.
%
% INPUT:
% - Transducer: struct holding the transducer dimensions.
%
% OUTPUT:
% - TRANS_SURFACE: Vertices of the transducer surface (4x3)
%
% Nathan Blanken, University of Twente, 2022

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRANSDUCER PROPERTIES
p = Transducer.Pitch;                 % [m]
w = Transducer.ElementWidth;          % [m]
N = Transducer.NumberOfElements;

% Compute transducer width and height:
W = p*(N-1) + w;                      % [m]
H = Transducer.ElementHeight;         % [m]


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRANSDUCER SURFACE VERTICES
if isfield(Transducer,'Configuration') && ...
        strcmp(Transducer.Configuration,'Custom')
    
    points = reshape(Transducer.integration_points,[],3);
    
    x0 = min(points(:,1));
    yl = min(points(:,2));
    yr = max(points(:,2));
    zb = min(points(:,3));
    zt = max(points(:,3));
    
else
    x0 = 0;
    yl = -W/2;
    yr =  W/2;
    zb = -H/2;
    zt =  H/2;
end

Xt = [x0 x0 x0 x0];
Yt = [yr yl yl yr];
Zt = [zt zt zb zb];

TRANS_SURFACE = transpose([Xt; Yt; Zt]);

end

function endDepth = compute_end_depth(Geometry)
% Compute the end depth of the geometry based on the maximum seperation of
% the bounding box vertices along the x axis.

% Vertices of cube with sides of unit length (3-by-8 array):
P = [-1 -1 -1 -1 1 1 1 1; -1 -1 1 1 -1 -1 1 1; -1 1 -1 1 -1 1 -1 1]/2;

% Bounding box of the geometry centred about the origin:
BB = Geometry.BoundingBox.Diagonal.*P;

% Rotate the bounding box:
BB = Geometry.Rotation*BB;

endDepth = Geometry.startDepth + max(BB(1,:))-min(BB(1,:));

end