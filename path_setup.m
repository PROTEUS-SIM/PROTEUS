function PATHS = path_setup()
%PATH_SETUP finds the full paths to the installed modules and data folders
%and stores them in a struct PATHS.
%
% Default locations (relative to the repository root):
%   k-Wave 1.4.x        external/k-wave/k-Wave
%   k-Wave binaries     external/k-wave/k-Wave/binaries
%   vtkToolbox          external/vtkToolbox
%   Flow geometries     geometry_data
%   Ground truth        ground_truth_frames   (created if missing)
%   Results, H5 files   RESULTS               (created if missing)
%   Settings            simulation-settings   (created if missing)
%
% Custom locations are read, in this order of precedence, from:
%   1. the file named by the environment variable PROTEUS_LOCAL_PATHS;
%   2. proteus_local_paths.m in the repository root (not tracked by git;
%      copy proteus_local_paths.template.m to create it);
%   3. PATHS.mat in the repository root (legacy format, deprecated).
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
PATHS.VtkToolboxPath     = '';

%==========================================================================
% CHECK FOR USER-DEFINED DIRECTORIES
%==========================================================================
custom = read_custom_paths(startDirectory);
names = fieldnames(custom);
for n = 1:numel(names)
    if ~isfield(PATHS, names{n}) || any(strcmp(names{n}, ...
            {'Start','GUIfunctions','StreamlineFunctions'}))
        error('path_setup:unknownField', ...
            'Unknown path ''%s'' in the custom path definitions.', names{n})
    end
    PATHS.(names{n}) = char(custom.(names{n}));
end

%==========================================================================
% AUTO-ASSIGN DIRECTORIES NOT DEFINED BY USER
%==========================================================================
defaults = {
    'kWavePath',          fullfile('external','k-wave','k-Wave')
    'VoxelisationPath',   fullfile('mesh-voxelisation','Mesh_voxelisation')
    'GeometriesPath',     'geometry_data'
    'GroundTruthPath',    'ground_truth_frames'
    'AcousticModulePath', 'acoustic-module'
    'ResultsPath',        'RESULTS'
    'SettingsPath',       'simulation-settings'
    'DataPath',           'RESULTS'
    'MicrobubblePath',    'microbubble-simulator'
    'VtkToolboxPath',     fullfile('external','vtkToolbox')};

for n = 1:size(defaults,1)
    if isempty(PATHS.(defaults{n,1}))
        PATHS.(defaults{n,1}) = fullfile(startDirectory, defaults{n,2});
    end
end

if isempty(PATHS.BinaryPath)
    PATHS.BinaryPath = fullfile(PATHS.kWavePath,'binaries');
end


%==========================================================================
% CHECK IF DIRECTORIES EXIST
%==========================================================================
missing_module_msg   = ['Install the module in the correct' ...
        ' location or specify the correct path to the module' ...
        ' (see proteus_local_paths.template.m).'];

missing_data_msg     = ['Install the data in the correct' ...
        ' location or specify the correct path to the data' ...
        ' (see proteus_local_paths.template.m).'];

missing_binaries_msg = ['Install the binaries in the correct' ...
        ' location or specify the correct path to the binaries' ...
        ' (see proteus_local_paths.template.m).'];

required = {
    'VoxelisationPath',   missing_module_msg
    'kWavePath',          missing_module_msg
    'BinaryPath',         missing_binaries_msg
    'GeometriesPath',     missing_data_msg
    'AcousticModulePath', missing_module_msg
    'MicrobubblePath',    missing_module_msg};

for n = 1:size(required,1)
    folder = PATHS.(required{n,1});
    if ~exist(folder, 'dir')
        error('path_setup:missingFolder', ...
            'The folder %s does not exist. %s', folder, required{n,2})
    end
end

check_kwave_version(PATHS.kWavePath);

created = {'GroundTruthPath','ResultsPath','SettingsPath','DataPath'};
for n = 1:numel(created)
    folder = PATHS.(created{n});
    if ~exist(folder, 'dir')
        mkdir(folder)
        disp(['Created directory ' folder '.'])
    end
end

end


function custom = read_custom_paths(startDirectory)
% Read user-defined paths. Returns a struct whose fields are PATHS fields.

custom = struct();

file = getenv('PROTEUS_LOCAL_PATHS');
if isempty(file)
    file = fullfile(startDirectory,'proteus_local_paths.m');
elseif ~isfile(file)
    error('path_setup:missingConfig', ['PROTEUS_LOCAL_PATHS points to ' ...
        '%s, which does not exist.'], file)
end

if isfile(file)
    custom = run_paths_file(file);
    custom = remove_empty_fields(custom);
    return
end

% Legacy format: a table with columns Description and Path in PATHS.mat.
legacyFile = fullfile(startDirectory,'PATHS.mat');
if isfile(legacyFile)
    S = load(legacyFile,'PATHS');
    T = S.PATHS;
    map = {
        'k-Wave',                    'kWavePath'
        'Mesh voxelisation toolbox', 'VoxelisationPath'
        'H5 files',                  'DataPath'
        'k-Wave binaries',           'BinaryPath'
        'Flow geometry data',        'GeometriesPath'
        'Ground truth frames',       'GroundTruthPath'
        'Results',                   'ResultsPath'
        'Simulation settings',       'SettingsPath'
        'Microbubble module',        'MicrobubblePath'};
    for n = 1:size(T,1)
        idx = strcmp(map(:,1), T.Description{n});
        if any(idx)
            custom.(map{idx,2}) = T.Path{n};
        end
    end
    custom = remove_empty_fields(custom);
    if ~isempty(fieldnames(custom))
        warning('path_setup:legacyPATHS', ['Reading custom paths from ' ...
            'PATHS.mat is deprecated. Move them to proteus_local_paths.m ' ...
            '(see proteus_local_paths.template.m).'])
    end
end
end


function PATHS_LOCAL = run_paths_file(file__)
% Evaluate a paths definition file, which must define the struct
% PATHS_LOCAL. The file content is evaluated (rather than run) so that any
% file name works, and in this separate workspace so that it cannot
% interfere with the variables of path_setup.
PATHS_LOCAL = struct();
eval(fileread(file__));
if ~isstruct(PATHS_LOCAL)
    error('path_setup:invalidConfig', ...
        'PATHS_LOCAL in %s must be a struct.', file__)
end
names = fieldnames(PATHS_LOCAL);
for n = 1:numel(names)
    value = PATHS_LOCAL.(names{n});
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error('path_setup:invalidConfig', ...
            'PATHS_LOCAL.%s in %s must be text.', names{n}, file__)
    end
end
end


function S = remove_empty_fields(S)
names = fieldnames(S);
for n = 1:numel(names)
    if isempty(S.(names{n}))
        S = rmfield(S, names{n});
    end
end
end


function check_kwave_version(kWavePath)
% PROTEUS requires k-Wave 1.4.x (tested with 1.4.1).
contentsFile = fullfile(kWavePath,'Contents.m');
version = '';
if isfile(contentsFile)
    tokens = regexp(fileread(contentsFile), ...
        '%\s*Version\s+(\d+)\.(\d+)(?:\.(\d+))?', 'tokens', 'once');
    if ~isempty(tokens)
        version = strjoin(tokens(~cellfun(@isempty,tokens)), '.');
    end
end

if isempty(version)
    warning('path_setup:kWaveVersion', ['Could not determine the ' ...
        'k-Wave version in %s. PROTEUS requires k-Wave 1.4.1.'], kWavePath)
elseif ~startsWith(version, '1.4')
    error('path_setup:kWaveVersion', ['PROTEUS requires k-Wave 1.4.x ' ...
        '(tested with 1.4.1), but k-Wave %s was found in %s.'], ...
        version, kWavePath)
end
end
