function generate_streamlines(Geometry, Microbubble, Acquisition, ...
    PATHS, savefolder, showStreamlines)
% Track microbubbles flowing through the flow vector field given by the vtu
% file in the specified geometry folder. When a bubble reaches an outlet of
% the vessel, a new bubble is generated at the inlet to keep the bubble
% count constant. For each frame, the positions, velocities, stream
% numbers, and radii of the bubbles are stored. The stream number indicates
% how often a bubble has been refreshed (1 corresponding to the first
% streamline, no refreshing).
%
% Nathan Blanken, University of Twente, 2023
% Guillaume Lajoinie, University of Twente, 2023

%==========================================================================
% GET USER PARAMETERS
%==========================================================================

% Folder containing the geometry data:
geometryFolder = [PATHS.GeometriesPath filesep Geometry.Folder];

frameRate  = Acquisition.FrameRate; % [Hz]
NFrames    = Acquisition.NumberOfFrames;
NPulses    = Acquisition.NumberOfPulses;
timeBetweenPulses = Acquisition.TimeBetweenPulses;

% Number of bubbles at each moment in the vessel:
NBubbles   = Microbubble.Number;

% Microbubble size distribution P(R):
P = Microbubble.Distribution.Probabilities;
R = Microbubble.Distribution.Radii;

% Use parallel computing for the microbubble tracking:
if isfield(Acquisition,'ParallelTracking')
    useparfor = Acquisition.ParallelTracking;
else
    useparfor = false;
end

%==========================================================================
% READ VTU DATA AND INLET DATA
%==========================================================================

% MATLAB file with VTU data of the flow simulation:
filename = [geometryFolder filesep 'vtu.mat'];
GeometryPropertiesFilename = ...
    [geometryFolder filesep 'GeometryProperties.mat'];

load(GeometryPropertiesFilename,'vtuProperties')
[vtuStruct, Grid] = load_vessel_data(filename, vtuProperties);

% Load the inlet points:
inlet = load([geometryFolder filesep 'inlet.mat'],'inlet');
inlet = inlet.inlet;

%--------------------------------------------------------------------------
% ODE solver options
%--------------------------------------------------------------------------

load(GeometryPropertiesFilename,'options');
options = odeset(options,'Events',@(t,y)exitVesselFcn(t,y,Grid));

% Function handle to the ODE:
odefun = @(t,y) transpose(...
    get_velocity(transpose(y), Grid, vtuStruct.velocities));


%==========================================================================
% COMPUTE STREAMLINES
%==========================================================================

% Matrices for holding the microbubble positions, velocities, streamline
% counts, and radii:
streamlines   = zeros(NPulses*NFrames, NBubbles,3);
velocities    = zeros(NPulses*NFrames, NBubbles,3);
streamNumbers = zeros(NPulses*NFrames, NBubbles);
radii         = zeros(NPulses*NFrames, NBubbles);

t1 = tic;
if showStreamlines; h = figure(); end

if useparfor
    
    %----------------------------------------------------------------------
    % PARALLEL COMPUTING OF STREAMLINES
    %----------------------------------------------------------------------
    
    % Cells for storing the output of the parallel operations:
    streamlines_cell   = cell(1, NBubbles);
    velocities_cell    = cell(1, NBubbles);
    streamNumbers_cell = cell(1, NBubbles);
    radii_cell         = cell(1, NBubbles);

    parfor n = 1:NBubbles

        disp(['Tracking microbubble ' num2str(n)...
            ' of ' num2str(NBubbles) '.']);

        % Track the bubble:
        [...
            streamlines_cell{   n}, ...
            velocities_cell{    n}, ...
            streamNumbers_cell{ n}, ...
            radii_cell{         n}  ...
            ] = ...
            track_bubble(Microbubble, Acquisition, Grid, ...
            vtuStruct, inlet, odefun, options, showStreamlines);    
    end

    % Assign the streamline values in the cells to the matrices:
    for n = 1:NBubbles
        streamlines(  :, n,:) = streamlines_cell{   n};
        velocities(   :, n,:) = velocities_cell{    n};
        streamNumbers(:, n)   = streamNumbers_cell{ n};
        radii(        :, n)   = radii_cell{         n};
    end
    
else
    
    %----------------------------------------------------------------------
    % SERIAL COMPUTING OF STREAMLINES
    %----------------------------------------------------------------------
    
    for n = 1:NBubbles
        
        disp(['Tracking microbubble ' num2str(n)...
            ' of ' num2str(NBubbles) '.']);

        % Track the bubble:
        [...
            streamlines(   :, n, :), ...
            velocities(    :, n, :), ...
            streamNumbers( :, n), ...
            radii(         :, n) ...
            ] = ...
            track_bubble(Microbubble, Acquisition, Grid, ...
            vtuStruct, inlet, odefun, options, showStreamlines);
        
    end
    
end

toc(t1)
if showStreamlines; close(h); end

%==========================================================================
% SAVE DATA
%==========================================================================

disp('Saving data ...')

streamlines   = reshape(streamlines,   NPulses, NFrames, NBubbles, 3);
velocities    = reshape(velocities,    NPulses, NFrames, NBubbles, 3);
streamNumbers = reshape(streamNumbers, NPulses, NFrames, NBubbles);
radii         = reshape(radii,         NPulses, NFrames, NBubbles);

if ~exist([PATHS.GroundTruthPath filesep savefolder],'dir')
    mkdir([PATHS.GroundTruthPath filesep savefolder]);
end

% Save the streamline generation parameters:
FlowSimulationParameters.TimeBtwPulse   = timeBetweenPulses;
FlowSimulationParameters.FrameRate      = frameRate;
FlowSimulationParameters.NBPulses       = NPulses;
FlowSimulationParameters.NMicrobubbles  = NBubbles;
FlowSimulationParameters.NumberOfFrames = NFrames;

FlowSimulationParameters.Microbubble.Distribution.Probabilities = P;
FlowSimulationParameters.Microbubble.Distribution.Radii         = R;

save([PATHS.GroundTruthPath, filesep, savefolder, ...
    filesep,'FlowSimulationParameters.mat'],'FlowSimulationParameters');

% Save the ground truth frames:
for m = 1:NFrames
    for n = 1:NPulses

        pulse = ['Pulse' num2str(n)];

        Frame.(pulse).Points       = reshape(streamlines(   n,m,:,:), NBubbles, 3);
        Frame.(pulse).Velocity     = reshape(velocities(    n,m,:,:), NBubbles, 3);
        Frame.(pulse).Radius       = reshape(radii(         n,m,:,:), NBubbles, 1);
        Frame.(pulse).StreamNumber = reshape(streamNumbers( n,m,:,:), NBubbles, 1);

    end
    
    NumOfFramesPadding=num2str(length(num2str(NFrames)));
    save([PATHS.GroundTruthPath,filesep,savefolder,filesep,...
        'Frame_',num2str(m,['%0',NumOfFramesPadding,'i']),'.mat'],'Frame');
end

end



function [streamlines, velocities, streamNumbers, radii] = ...
    track_bubble(Microbubble, Acquisition, Grid, vtuStruct, inlet, ...
    odefun, options, showStreamlines)

%--------------------------------------------------------------------------
% GET USER PARAMETERS
%--------------------------------------------------------------------------

frameRate  = Acquisition.FrameRate; % [Hz]
NFrames    = Acquisition.NumberOfFrames;
NPulses    = Acquisition.NumberOfPulses;
timeBetweenPulses = Acquisition.TimeBetweenPulses;

% Time arrays with acquisition times and sequence times:
acquisitionTimes = (0:(NFrames - 1))/frameRate;
sequenceTimes    = (0:(NPulses - 1))*timeBetweenPulses;

% numberOfFrames-by-numberOfPulses time array:
acquisitionTimes = acquisitionTimes + transpose(sequenceTimes);

% Reshape into a row vector:
acquisitionTimes = reshape(acquisitionTimes,1,NPulses*NFrames);

% Microbubble size distribution P(R):
P = Microbubble.Distribution.Probabilities;
R = Microbubble.Distribution.Radii;

streamlines   = zeros(NPulses*NFrames,1,3);
velocities    = zeros(NPulses*NFrames,1,3);
streamNumbers = zeros(NPulses*NFrames,1,1);
radii         = zeros(NPulses*NFrames,1,1);

% Position the bubble in the bulk of the vessel:
startPosition = draw_start_position(1, vtuStruct);

tspan = acquisitionTimes;

streamCount = 1; % Streamline count
t = -Inf;

while max(t)<max(acquisitionTimes)

    %------------------------------------------------------------------
    % COMPUTE STREAMLINE
    %------------------------------------------------------------------
    if length(tspan)<2
        t = tspan; positions = startPosition;
    else 
        [t,positions] = ode23(odefun,tspan,startPosition(:),options);
    end

    %------------------------------------------------------------------
    % PLOT STREAMLINE
    %------------------------------------------------------------------
    if showStreamlines
        plot3(positions(:,1),positions(:,2),positions(:,3));
        xlabel('X (m)')
        ylabel('Y (m)')
        zlabel('Z (m)')
        hold on
        drawnow
    end

    %------------------------------------------------------------------
    % STORE STREAMLINE
    %------------------------------------------------------------------
    % Find the mutual times in both time arrays:
    [~,I,I_acquisition] = intersect(t,acquisitionTimes);

    streamlines(I_acquisition, 1,:) = positions(I,:);
    streamNumbers(I_acquisition, 1) = streamCount;

    % Get the velocities at the microbubble positions:
    velocities(I_acquisition, 1,:) = get_velocity(...
        positions(I,:), Grid, vtuStruct.velocities);

    % Draw a radius from the size distribution:
    radii(I_acquisition, 1) = draw_random_radii(P,R,1);

    %------------------------------------------------------------------
    % GET A NEW BUBBLE
    %------------------------------------------------------------------
    % Position a new bubble at the inlet:
    startPosition = draw_start_position(1, inlet);

    % Update time array (remaining time):
    tspan = acquisitionTimes(find(acquisitionTimes>t(end),1):end);

    streamCount = streamCount + 1;

end

end