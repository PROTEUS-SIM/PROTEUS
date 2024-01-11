% Clear workspace, clear command window, close all figures:
clear; clc; close all

% Add the root directory of the repository to the MATLAB path:
addpath('..')

% Get paths to the modules:
PATHS = path_setup();

% Enter the name of the GUI parameter file to use. If the GUI parameter
% file in not located in the simulation-settings folder, enter the full
% path.
GUIfilename = 'GUI_output_parameters.mat';

% Enter the name of the subfolder containing the ground truth bubble
% locations. This folder must be located in the folder ground_truth_frames.
groundTruthFolder = 'example_ground_truth';

% Enter the name of the folder in which you want to save the results. If
% nonexistent, a new folder will be automatically created in the folder
% RESULTS:
saveFolder = 'example_RF_data';

% Add the acoustic module to the MATLAB path:
addpath(PATHS.AcousticModulePath)

% Run the simulation:
main_RF(GUIfilename, groundTruthFolder, saveFolder);