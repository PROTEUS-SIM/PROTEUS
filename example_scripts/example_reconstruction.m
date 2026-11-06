% EXAMPLE DAS RECONSTRUCTION CODE

% Clear workspace, clear command window, close all figures:
clear; clc; close all

% Add the root directory of the repository to the MATLAB path:
addpath('..')

% Add the delay-and-sum folder to the MATLAB path:
addpath(fullfile('..','delay-and-sum'))

PATHS = path_setup();

% The general beamformer uses the transducer geometry in GUIfunctions:
addpath(PATHS.GUIfunctions)

% Beamformer: DAS_reconstruction (linear arrays, plane or diverging waves)
% or DAS_reconstruction_general (linear and curved arrays, steering and
% focusing; under test against DAS_reconstruction). Any function with the
% same interface can be used, see delay-and-sum/README.md.
beamformer = @DAS_reconstruction;

% Select the folder containing the RF data:
resultsFolder = uigetdir(PATHS.ResultsPath, ...
    'Select the folder containing the RF data');

% Select the file containing the simulation settings:
[GUIfilename, pathname] = uigetfile(fullfile(PATHS.SettingsPath, '*.mat'),...
    'Select the simulation settings file');
GUIfilepath = [pathname GUIfilename];

% Perform the DAS reconstruction
% IMG is Nx-by-Ny-by-Nframes: x axial, y lateral (PROTEUS convention)
[IMG,x,y] = beamformer(resultsFolder,GUIfilepath);

% Create a video with all the frames
videoFileName = [GUIfilename(1:end-4) '_DAS_recon.mp4'];
write_video(IMG,x,y,videoFileName)

close all