function S = make_default_settings(PATHS, geometryFolder, transducerMode)
%MAKE_DEFAULT_SETTINGS Headless equivalent of the MainGUI start-up.
%
% S = MAKE_DEFAULT_SETTINGS(PATHS) returns a struct with the fields
% Microbubble, Medium, Acquisition, Transducer, Transmit,
% SimulationParameters and Geometry, initialised exactly as MainGUI does
% in startupFcn followed by updateParameters.
%
% S = MAKE_DEFAULT_SETTINGS(PATHS, geometryFolder) selects another flow
% geometry folder in PATHS.GeometriesPath (default: 'renal_tree').
%
% S = MAKE_DEFAULT_SETTINGS(PATHS, geometryFolder, transducerMode) with
% transducerMode 'reference' (default) uses the default transducer as in
% the reference code (see reference_transducer), and with 'current' the
% default transducer of this version (with the calibrated impulse
% response if Transducer-models/P4-1.mat exists).

if nargin < 2
    geometryFolder = 'renal_tree';
end
if nargin < 3
    transducerMode = 'reference';
end

S.Microbubble          = reset_microbubble();
S.Medium               = reset_medium();
S.Acquisition          = reset_acquisition();
S.Transducer           = reset_transducer();
if strcmp(transducerMode,'reference')
    S.Transducer = reference_transducer(S.Transducer);
end
S.Transmit             = reset_transmit(S.Transducer);
S.SimulationParameters = reset_simulation_parameters();

Geometry.Folder = geometryFolder;
S.Geometry = reset_geometry(Geometry, PATHS);

S = update_derived_settings(S);
end
