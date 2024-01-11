function PATHS = path_setup()
%PATH_SETUP finds the full paths to the installed modules and data folders
%and stores them in a struct PATHS.
%
% PATH_SETUP first searches for custom paths in the file PATHS.mat. If no
% custom paths are found, the default installation paths are assigned.
%
% Note: the location of this function is used to find the full path to the
% root directory of the repository. It should therefore not be moved to
% another location.
%
% Nathan Blanken, University of Twente, 2023

% Full path to current function:
currentFile = mfilename('fullpath');

% Full path to the start directory:
startDirectory = fileparts(currentFile);

PATHS.Start               = startDirectory;
PATHS.GUIfunctions        = fullfile(startDirectory,'GUIfunctions');
PATHS.StreamlineFunctions = fullfile(startDirectory,'streamline-module');

paths = load(fullfile(startDirectory,'PATHS.mat'),'PATHS');
PATHS_TABLE = paths.PATHS;

% Preallocate paths:
PATHS.kWavePath          = '';
PATHS.VoxelisationPath   = '';
PATHS.DataPath           = '';
PATHS.BinaryPath         = '';
PATHS.GeometriesPath     = '';
PATHS.GroundTruthPath    = '';
PATHS.AcousticModulePath = '';
PATHS.ResultsPath        = '';
PATHS.MicrobubblePath    = '';
PATHS.SettingsPath       = '';

%==========================================================================
% CHECK FOR USER-DEFINED DIRECTORIES
%==========================================================================
for n = 1:size(PATHS_TABLE,1)
    switch PATHS_TABLE.Description{n}
        case 'k-Wave'
            PATHS.kWavePath          = PATHS_TABLE.Path{n};
            
        case 'Mesh voxelisation toolbox'
            PATHS.VoxelisationPath   = PATHS_TABLE.Path{n};
            
        case 'H5 files'
            PATHS.DataPath           = PATHS_TABLE.Path{n};
            
        case 'k-Wave binaries'
            PATHS.BinaryPath         = PATHS_TABLE.Path{n};
            
        % Path to geometry data sets:
        case 'Flow geometry data'
            PATHS.GeometriesPath     = PATHS_TABLE.Path{n};
            
        % Path ground truth data:
        case 'Ground truth frames'
            PATHS.GroundTruthPath    = PATHS_TABLE.Path{n};
                       
        % Path to results:
        case 'Results'
            PATHS.ResultsPath        = PATHS_TABLE.Path{n};
            
        % Path to simulation settings:
        case 'Simulation settings'
            PATHS.SettingsPath       = PATHS_TABLE.Path{n};
            
        % Path to microbubble module:
        case 'Microbubble module'
            PATHS.MicrobubblePath    = PATHS_TABLE.Path{n};
    end
end


%==========================================================================
% AUTO-ASSIGN DIRECTORIES NOT DEFINED BY USER
%==========================================================================
if isempty(PATHS.kWavePath)
    PATHS.kWavePath = fullfile(startDirectory,...
        'k-wave-toolbox-version-1.3','k-Wave');
end

if isempty(PATHS.VoxelisationPath)
    PATHS.VoxelisationPath = fullfile(startDirectory,...
        'mesh-voxelisation','Mesh_voxelisation');
end

if isempty(PATHS.GeometriesPath)
    PATHS.GeometriesPath = fullfile(startDirectory,...
        'geometry_data');
end

if isempty(PATHS.GroundTruthPath)
    PATHS.GroundTruthPath = fullfile(startDirectory,...
        'ground_truth_frames');
end

if isempty(PATHS.AcousticModulePath)
    PATHS.AcousticModulePath = fullfile(startDirectory,...
        'acoustic-module');
end

if isempty(PATHS.ResultsPath)
    PATHS.ResultsPath = fullfile(startDirectory,...
        'RESULTS');
end

if isempty(PATHS.SettingsPath)
    PATHS.SettingsPath = fullfile(startDirectory,...
        'simulation-settings');
end

if isempty(PATHS.DataPath)
    PATHS.DataPath = fullfile(startDirectory,...
        'RESULTS');
end

if isempty(PATHS.BinaryPath)
    PATHS.BinaryPath = fullfile(startDirectory,...
        'k-wave-toolbox-version-1.3','k-Wave','binaries');
end

if isempty(PATHS.MicrobubblePath)
    PATHS.MicrobubblePath = fullfile(startDirectory,...
        'microbubble-simulator');
end


%==========================================================================
% CHECK IF DIRECTORIES EXIST
%==========================================================================
missing_module_msg   = ['Install the module in the in the correct' ...
        ' location or specify the correct path to the module.'];
    
missing_data_msg     = ['Install the data in the in the correct' ...
        ' location or specify the correct path to the data.'];
    
missing_binaries_msg = ['Install the binaries in the in the correct' ...
        ' location or specify the correct path to the binaries.'];
    
if ~exist(PATHS.VoxelisationPath, 'dir')
    msg = ['The folder ' PATHS.VoxelisationPath ' does not exist. ' ...
        missing_module_msg];
    error(msg)
end

if ~exist(PATHS.kWavePath, 'dir')
    msg = ['The folder ' PATHS.kWavePath ' does not exist. ' ...
        missing_module_msg];
    error(msg)
end

if ~exist(PATHS.BinaryPath, 'dir')
    msg = ['The folder ' PATHS.BinaryPath ' does not exist. ' ...
        missing_binaries_msg];
    error(msg)
end

if ~exist(PATHS.GeometriesPath, 'dir')
    msg = ['The folder ' PATHS.GeometriesPath ' does not exist. ' ...
        missing_data_msg];
    error(msg)
end

if ~exist(PATHS.GroundTruthPath, 'dir')
    mkdir(PATHS.GroundTruthPath)
    disp(['Created directory ' PATHS.GroundTruthPath '.'])
end

if ~exist(PATHS.AcousticModulePath, 'dir')
    msg = ['The folder ' PATHS.AcousticModulePath ' does not exist. ' ...
        missing_module_msg];
    error(msg)
end

if ~exist(PATHS.MicrobubblePath, 'dir')
    msg = ['The folder ' PATHS.MicrobubblePath ' does not exist. ' ...
        missing_module_msg];
    error(msg)
end

if ~exist(PATHS.ResultsPath, 'dir')
    mkdir(PATHS.ResultsPath)
    disp(['Created directory ' PATHS.ResultsPath '.'])
end

if ~exist(PATHS.SettingsPath, 'dir')
    mkdir(PATHS.SettingsPath)
    disp(['Created directory ' PATHS.SettingsPath '.'])
end

if ~exist(PATHS.DataPath, 'dir')
    mkdir(PATHS.DataPath)
    disp(['Created directory ' PATHS.DataPath '.'])
end

end