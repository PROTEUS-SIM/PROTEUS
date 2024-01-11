% Clear workspace, clear command window, close all figures:
clear; clc; close all

% Add the root directory of the repository to the MATLAB path:
addpath('..')

% Get paths to the modules:
PATHS = path_setup();

% Enter the name of the GUI parameter file to use:
GUIfilename = fullfile(PATHS.SettingsPath,'GUI_output_parameters.mat');

% Enter the name of the folder in which you want to save the results.
saveFolder = fullfile(PATHS.ResultsPath,'example_medium');

% Add the acoustic module to the MATLAB path:
addpath(PATHS.AcousticModulePath)

% Folder containing flow geometry data:
geometriesPath = PATHS.GeometriesPath;

% Create save directory if nonexistent:
if ~isfolder(saveFolder)
    mkdir(saveFolder)
end

% Load the settings file:
load(GUIfilename,'Geometry','Medium','SimulationParameters')

% Location of the geometry data:
Geometry.GeometriesPath = geometriesPath;

% Create the grid:
disp('Creating k-Wave grid ...')
[~, Grid] = define_grid(SimulationParameters, Geometry);

% Create and save the k-Wave medium:
disp('Creating k-Wave medium ...')
[medium, vessel_grid] = define_medium(Grid, Medium, Geometry);
disp('Saving k-Wave medium ...')
save([saveFolder '/medium.mat'],'medium','vessel_grid','Grid','-v7.3')
