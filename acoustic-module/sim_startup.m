function [settingspath, groundtruthpath, savepath] = ...
    sim_startup(settingsfile, groundtruthfolder, savefolder)

% Full path to current function:
currentFile = mfilename('fullpath');

% Full path to acoustic module:
acousticModulePath = fileparts(currentFile);

% Full path to main directory:
startDirectory = fileparts(acousticModulePath);

addpath(acousticModulePath)
addpath(startDirectory)

% Get paths to the required folders:
PATHS = path_setup();

% Convert string to character vector (if not already):
settingsfile = char(settingsfile);

% Add file extension if missing:
[~,~,ext] = fileparts(settingsfile);
if isempty(ext)
    settingsfile = [settingsfile '.mat'];
end

% Full path to the settings file:
settingspath = fullfile(PATHS.SettingsPath, settingsfile);

% Full path to the ground truth data:
groundtruthpath = fullfile(PATHS.GroundTruthPath, groundtruthfolder);

% Full path to the folder in which to save the RF data:
savepath = fullfile(PATHS.ResultsPath, savefolder);

% If the file does not exist in the simulation settings folder, use the
% input as the full path:
if ~exist(settingspath,'file')
    settingspath = settingsfile;
end

% If the file does not exist, throw error:
if ~exist(settingspath,'file')
    error(['File ' settingspath ' not found']);
end

end