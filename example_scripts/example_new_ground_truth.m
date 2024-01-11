% Clear workspace, clear command window, close all figures:
clear; clc; close all

% Add the root directory of the repository to the MATLAB path:
addpath('..')

% Get paths to the modules:
PATHS = path_setup();

% Enter the name of the GUI parameter file to use:
GUIfilename = fullfile(PATHS.SettingsPath,'GUI_output_parameters.mat');

% Enter the name of the subfolder containing the ground truth bubble
% locations. This folder must be located in the folder ground_truth_frames.
groundTruthFolder = 'example_ground_truth';

% Add the relevant modules to the MATLAB path:
addpath(PATHS.StreamlineFunctions)
addpath(PATHS.GUIfunctions)

% Load the settings file:
load(GUIfilename,'Geometry','Microbubble','Acquisition')

showStreamlines = false; % Do not show streamlines
generate_streamlines(Geometry, Microbubble, Acquisition,...
    PATHS, groundTruthFolder, showStreamlines)

% Show the ground truth positions:
show_microbubble_positions(...
    fullfile(PATHS.GroundTruthPath, groundTruthFolder),Geometry,PATHS)

