function check_ground_truth_data(folder, Acquisition, Microbubble, savedir)
% Check if the flow simulation parameters in folder match the settings in
% Acquisition and Microbubble. If the parameters match, save the flow
% simulation parameters in savedir.
%
% INPUT:
% - folder: the path to the ground truth data, which must include a file
%   named 'FlowSimulationParameters.mat';
%
% - savedir: the path to the results folder
%
% Compares: the number of frames, the frame rate, the number of
% microbubbles, the number of pulses, and the time between pulses.
%
% Also compares the microbubble distributions. A difference in microbubble
% distributions only results in a warning, not an error.
%
% Nathan Blanken, University of Twente, 2023

%==========================================================================
% LOAD THE GROUND TRUTH DATA FLOW SIMULATION PARAMETERS
%==========================================================================
load(fullfile(folder,'FlowSimulationParameters.mat'), ...
    'FlowSimulationParameters')

%==========================================================================
% Compare the number of frames, the frame rate, the number of microbubbles,
% the number of pulses, and the time between pulses.
%==========================================================================
param = '';

T1 = FlowSimulationParameters.TimeBtwPulse;
T2 = Acquisition.TimeBetweenPulses;

FR1 = FlowSimulationParameters.FrameRate;
FR2 = Acquisition.FrameRate;

d = 6;    % Numeric precision for comparison (number of digits)
p = 1e-6; % Numeric precision for comparison (value)

if (FlowSimulationParameters.NBPulses > 1) && ...
        str2double(num2str(T1,d)) ~= str2double(num2str(T2,d))
    param = 'time between pulses';
end

if FlowSimulationParameters.NBPulses ~= ...
        Acquisition.NumberOfPulses
    param = 'number of pulses';
end

if FlowSimulationParameters.NMicrobubbles ~= ...
        Microbubble.Number
    param = 'number of microbubbles';
end

if str2double(num2str(FR1,d)) ~= str2double(num2str(FR2,d))
    param = 'frame rate';
end

if FlowSimulationParameters.NumberOfFrames ~= ...
        Acquisition.NumberOfFrames
    param = 'number of frames';
end

if ~isempty(param)
    error(['The ' param ' in the ground truth data and the ' param ...
        ' in the simulation settings do not match.'])
end

%==========================================================================
% Compare the microbubble size distributions.
%==========================================================================
P1 = Microbubble.Distribution.Probabilities;
P2 = FlowSimulationParameters.Microbubble.Distribution.Probabilities;

R1 = Microbubble.Distribution.Radii;
R2 = FlowSimulationParameters.Microbubble.Distribution.Radii;

param = 'microbubble size distribution';

size_distr_msg = ['The ' param ' in the ground truth data and the ' ...
    param ' in the simulation settings do not match.'];

% Compare array lengths:
if (length(P1) ~=  length(P2)) || (length(R1) ~=  length(R2))
    lengths_equal = false;
else
    lengths_equal = true;
end

% Compare array values:
if ~lengths_equal || ...
        max(abs(P1-P2))/max(P1)>p || max(abs(R1-R2))/max(R1)>p
    warning(size_distr_msg)
else
    disp(['Ground truth data OK.' newline])
end

%==========================================================================
% SAVE THE GROUND TRUTH PARAMETERS IN THE RESULTS FOLDER
%==========================================================================
% If ground truth data OK, save the flow simulation parameters in the
% results folder:

% Create save directory if nonexistent:
if ~isfolder(savedir)
    mkdir(savedir)
end

save(fullfile(savedir,'FlowSimulationParameters.mat'), ...
    'FlowSimulationParameters')

end