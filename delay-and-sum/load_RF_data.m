function RF_matrix = load_RF_data(resultsFolder,pulsingScheme)
% LOAD_RF_DATA reads RF data files and applies a pulsing scheme.
%
% RF = LOAD_RF_DATA(resultsFolder,pulsingScheme) reads the RF data in the
% folder resultsFolder and applies the pulsing scheme pulsingScheme to the
% data. RF is an Nelem-by-Nt-by-Nframes array, where Nelem is the number of
% transducer elements, Nt the number of time samples, and Nframes the
% number of frames.
%
% Guillaume Lajoinie, Nathan Blanken, University of Twente, 2023

% Get a list of all the frames in the results folder:
filelist = dir(fullfile(resultsFolder,'Frame*.mat'));

% Get the frame numbers of the files in the list:
FrameNumbers = arrayfun(@(F) str2double(F.name(7:end-4)),filelist);

% Sort the file list by frame number:
[~, I] = sort(FrameNumbers);
filelist = filelist(I);

% Load a sample RF data frame:
load(fullfile(filelist(1).folder, filelist(1).name),'RF');
RF = RF{1};

% RF data properties:
Nt = size(RF,2);    % Number of samples per RF line
Nelem = size(RF,1); % Number of transducer elements

% Total number of frames in the list:
Nframes = length(filelist);

disp('Loading data and applying pulsing scheme')
RF_matrix = zeros(Nelem,Nt,Nframes,class(RF));

for iframe = 1:Nframes
    
    load(fullfile(filelist(iframe).folder, filelist(iframe).name),'RF');
    
    switch pulsingScheme
        case 'Amplitude modulation'
            RF = RF{3}-RF{1}-RF{2};
        case 'Pulse inversion'
            RF = RF{1}+RF{2};
        case 'Amplitude modulation with pulse inversion'
            RF = RF{3}+RF{1}+RF{2};
        case 'Standard'
            RF = RF{1};
            
    end
    
    RF_matrix(:,:,iframe) = RF;
    
end

end