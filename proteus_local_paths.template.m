% PROTEUS LOCAL PATHS (template)
%
% Copy this file to proteus_local_paths.m in the same folder and edit it to
% use custom locations for dependencies or data. proteus_local_paths.m is
% ignored by git, so your paths stay on your machine.
%
% Leave a path empty ('') to use the default location (see path_setup.m).
% Use full paths. Alternatively, point the environment variable
% PROTEUS_LOCAL_PATHS to a file with the same content.

PATHS_LOCAL.kWavePath        = ''; % folder containing kWaveGrid.m (k-Wave 1.4.x)
PATHS_LOCAL.BinaryPath       = ''; % k-Wave C++/CUDA binaries (default: <kWavePath>/binaries)
PATHS_LOCAL.VtkToolboxPath   = ''; % vtkToolbox (only needed for vtu2matlab)
PATHS_LOCAL.GeometriesPath   = ''; % flow geometry data
PATHS_LOCAL.GroundTruthPath  = ''; % microbubble ground truth frames
PATHS_LOCAL.ResultsPath      = ''; % simulation results
PATHS_LOCAL.DataPath         = ''; % k-Wave input/output H5 files
PATHS_LOCAL.SettingsPath     = ''; % saved GUI settings
