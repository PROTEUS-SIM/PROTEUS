% EXAMPLE DAS RECONSTRUCTION CODE

% Clear workspace, clear command window, close all figures:
clear; clc; close all

% Add the root directory of the repository to the MATLAB path:
addpath('..')

% Add the delay-and-sum folder to the MATLAB path:
addpath('..\delay-and-sum')

PATHS = path_setup();

% Select the folder containing the RF data:
resultsFolder = uigetdir(PATHS.ResultsPath, ...
    'Select the folder containing the RF data');

% Select the file containing the simulation settings:
[GUIfilename, pathname] = uigetfile(fullfile(PATHS.SettingsPath, '*.mat'),...
    'Select the simulation settings file');
GUIfilepath = [pathname GUIfilename];

% Perform the DAS reconstruction
[IMG,z,x] = DAS_reconstruction(resultsFolder,GUIfilepath);

% Create a video with all the frames
videoFileName = [GUIfilename(1:end-4) '_DAS_recon.mp4'];
write_video(IMG,z,x,videoFileName)

close all