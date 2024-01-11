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

% If running on GPU, specify the GPU device number. If running on CPU, this
% number will be ignored. The GPU device numbers are counted from 0.
deviceNumber = 0;

% Total number of frames to simulate
NFrames = 500;
 
% Number of frames per simulation batch
NFramesPerBatch = 250;

% Frame number to start from:
startFrame = 1;

% Add the acoustic module to the MATLAB path:
addpath(PATHS.AcousticModulePath)

% If the simulation starts from the first frame, create a new simulation
% medium. Otherwise, reuse the existing one.
if startFrame > 1
    reuseMedium = true;
elseif startFrame == 1 
    reuseMedium = false;
end
 
% Batches of frames:
startFrames = startFrame:NFramesPerBatch:NFrames;

% Number of batches:
NBatch = length(startFrames);
 
% Loop over the simulation batches:
for k = 1:NBatch
 
    frameStart = startFrames(k);
    frameEnd   = min(frameStart + NFramesPerBatch - 1, NFrames);

    % Run the simulation batch:
    main_RF(...
        GUIfilename, ... 
        groundTruthFolder, ...
        saveFolder, ...
        reuseMedium , ...
        frameStart, ...
        frameEnd , ...
        deviceNumber);
 
    % After the first batch, the medium should be reused.
    reuseMedium = true;
 
end
 
% Display the total runtime of the simulation:
t1 = toc(t0);
t1 = seconds(t1);
t1.Format = 'hh:mm:ss';
display(t1)

clear t0 t1