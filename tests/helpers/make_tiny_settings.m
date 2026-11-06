function S = make_tiny_settings(PATHS, transducerMode)
%MAKE_TINY_SETTINGS Default settings shrunk to a seconds-long simulation.
%
% Uses the synthetic 'tiny_box' geometry (created by
% ProteusTestEnvironment), an 8-element version of the default transducer
% and a coarse grid. The physics is not meant to be realistic; the case
% exists to exercise the full pipeline quickly and deterministically.
%
% S = MAKE_TINY_SETTINGS(PATHS, transducerMode): see make_default_settings
% (default 'reference').

if nargin < 2
    transducerMode = 'reference';
end

S = make_default_settings(PATHS, 'tiny_box', transducerMode);

S.Geometry.startDepth = 1e-3;              % [m]

S.Transducer.NumberOfElements = 8;
S.Transducer.ElementHeight    = 2e-3;      % [m]
S.Transmit = reset_transmit(S.Transducer);

S.SimulationParameters.PointsPerWavelength = 4;

S.Microbubble.Number        = 4;
S.Acquisition.NumberOfFrames = 2;

S = update_derived_settings(S);
end
