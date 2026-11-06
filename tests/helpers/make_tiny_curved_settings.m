function S = make_tiny_curved_settings(PATHS)
%MAKE_TINY_CURVED_SETTINGS Tiny settings (see make_tiny_settings) with an
%8-element curved array (radius of curvature 3 mm, 22.5 degree half
%aperture).

S = make_tiny_settings(PATHS);

S.Transducer.Type          = 'Tiny curved';
S.Transducer.Configuration = 'Curved';
S.Transducer.Radius        = 3e-3;     % [m]
S.Transmit = reset_transmit(S.Transducer);

% Keep the microbubbles clear of the transducer sensor mask: unlike the
% flat array (on a grid plane), the curved surface is off the grid, so its
% mask extends 4 grid points (0.6 mm on this coarse grid) in x:
El = get_element_geometry(S.Transducer);
S.Geometry.startDepth = S.Geometry.startDepth + El.Apex + 0.7e-3;

S = update_derived_settings(S);
end
