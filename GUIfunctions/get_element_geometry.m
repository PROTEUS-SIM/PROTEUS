function El = get_element_geometry(Transducer)
%GET_ELEMENT_GEOMETRY Element positions of a linear or curved array.
%
% El = GET_ELEMENT_GEOMETRY(Transducer) returns a struct with fields:
% - x:      axial coordinates of the element centres (N-by-1) [m]
% - y:      lateral coordinates of the element centres (N-by-1) [m]
% - theta:  angle of the element normals with the x axis (N-by-1) [rad]
% - width:  width of each element along the array surface [m]
% - Radius: radius of curvature (Inf for a linear array) [m]
% - Apex:   axial coordinate of the centre of the array surface [m]
% - Center: axial coordinate of the centre of curvature (-Inf for a
%           linear array) [m]
% - ThetaMax: half the angular aperture of a curved array (0 for a linear
%           array) [rad]
%
% This function is the single definition of the array geometry, used by
% the transmit delays, the simulation domain, the integration points, the
% medium and the delay-and-sum reconstruction.
%
% CONVENTIONS (x axial, y lateral, z elevation):
% Linear array: the elements lie in the plane x = 0 and are centred about
% y = 0.
% Curved array (Transducer.Configuration = 'Curved'): the elements are a
% uniform subdivision of an arc of radius R, without kerf: element i spans
% the angles theta_i -/+ p/(2R), with theta_i = p*(i-(N+1)/2)/R and p the
% pitch. Transducer.ElementWidth is not used. The two outer edges of the
% array lie at x = 0, so the centre of curvature lies at
% x = -R*cos(N*p/(2R)) and the centre of the array surface (apex) at
% x = R - R*cos(N*p/(2R)).
%
% Element 1 has the most negative lateral coordinate.

N = Transducer.NumberOfElements;
p = Transducer.Pitch;
i = (1:N)';

if is_curved(Transducer)
    R = Transducer.Radius;
    if ~(isscalar(R) && isfinite(R) && R > 0)
        error('get_element_geometry:invalidRadius', ...
            'A curved array needs a positive finite Transducer.Radius.')
    end
    thetaMax = N*p/(2*R);
    if thetaMax >= pi/2
        error('get_element_geometry:invalidRadius', ...
            ['The arc of the curved array (N*Pitch) must be shorter ' ...
            'than pi*Radius.'])
    end
    xc = -R*cos(thetaMax);         % Axial position of centre of curvature

    El.theta    = p*(i-(N+1)/2)/R;
    El.x        = xc + R*cos(El.theta);
    El.y        = R*sin(El.theta);
    El.width    = p;
    El.Radius   = R;
    El.Apex     = xc + R;
    El.Center   = xc;
    El.ThetaMax = thetaMax;
else
    El.theta    = zeros(N,1);
    El.x        = zeros(N,1);
    El.y        = (i-(N+1)/2)*p;
    El.width    = Transducer.ElementWidth;
    El.Radius   = Inf;
    El.Apex     = 0;
    El.Center   = -Inf;
    El.ThetaMax = 0;
end

end

function tf = is_curved(Transducer)
tf = isfield(Transducer,'Configuration') && ...
    strcmp(Transducer.Configuration,'Curved');
end
