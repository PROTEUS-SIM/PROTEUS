function [Acquisition, SimulationParameters] = input_handling(...
    Acquisition, SimulationParameters, inputCell)
% Assign the optional input arguments collected in inputCell to the structs
% Acquisition and SimulationParameters.
%
% inputCell{1}: continue with the same k-Wave medium (boolean)
% inputCell{2}: frame number to continue from (integer)
% inputCell{3}: frame number to stop after (integer)
% inputCell{4}: GPU device number (counting from zero)
%
% Nathan Blanken, University of Twente, 2023

% Parameters for continuation of an interrupted simulation:
Nframes = Acquisition.NumberOfFrames;
Acquisition.Continue = false;   % Reuse the same medium
Acquisition.StartFrame = 1;     % Continue the simulation from this frame
Acquisition.EndFrame = Nframes; % Stop the simulation after this frame

if size(inputCell,2) > 0
    if isempty(inputCell{1})
        % Ignore input argument
    elseif islogical(inputCell{1})
        Acquisition.Continue = inputCell{1};        
    else
        error('varargin{1} must be a boolean value.')
    end
end

if size(inputCell,2) > 1
    if isempty(inputCell{2})
        % Ignore input argument
    elseif isnumeric(inputCell{2}) && ...
            (floor(inputCell{2}) == inputCell{2}) && (inputCell{2} > 0)
        Acquisition.StartFrame = inputCell{2};
    else
        error('varargin{2} must be a positive integer.')
    end
end

if size(inputCell,2) > 2
    if isempty(inputCell{3})
        % Ignore input argument
    elseif isnumeric(inputCell{3}) && ...
            (floor(inputCell{3}) == inputCell{3}) && (inputCell{3} > 0)
        Acquisition.EndFrame = min(inputCell{3}, Nframes);
    else
        error('varargin{3} must be a positive integer.')
    end
end

if size(inputCell,2) > 3
    if isempty(inputCell{4})
        % Ignore input argument
    elseif isnumeric(inputCell{4}) && (floor(inputCell{4}) == inputCell{4})
        SimulationParameters.DeviceNumber = inputCell{4};
        gpuDevice(inputCell{4}+1);
        disp(['Selected and reset GPU device ' num2str(inputCell{4}) '.']);
        
    else
        error('varargin{3} must be an integer.')
    end
end

end