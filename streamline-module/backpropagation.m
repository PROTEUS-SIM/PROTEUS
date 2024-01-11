%==========================================================================
% Backpropagating N streamlines to densely populate the inlet surface.
%
% The step tolerance parameter can be adjusted for maximum precision, but
% the voxelization of the simulation becomes the bottle neck for low
% values.
%==========================================================================

clear
clc
close all

% Use parallel computing for the streamline backpropagation:
useparfor = false;

%==========================================================================
% SETTINGS
%==========================================================================

% Folder containing the geometry data:
geometryFolder = ['..' filesep 'geometry_data'];
[vtufilename, pathname] = uigetfile([geometryFolder filesep '*vtu.mat'],...
    'Select vtu.mat file');

GeometryPropertiesFilename = 'GeometryProperties.mat';

% Number of streamlines to propagate back to the inlet:
Nstreamlines = 10e3;

% Percentile to take for reference velocity:
velocityPercentile = 0.95;

% Maximum number of grid points the ODE solver can skip over in one 
% integration step:
stepTolerance = 5; % leniency parameter

% Maximum integration time:
frameRate = 250; % [Hz]
numberOfFrames = 5e3;
Tmax = (numberOfFrames-1)/frameRate;

skip = 25; % Skip this number of points for plotting vessel

%==========================================================================
% READ VESSEL DATA
%==========================================================================

% MATLAB file with VTU data of the flow simulation:
vtufilepath = fullfile(pathname, vtufilename);
GeometryPropertiesPath = fullfile(pathname, GeometryPropertiesFilename);

load(GeometryPropertiesPath,'vtuProperties')
[vtuStruct, Grid] = load_vessel_data(vtufilepath,vtuProperties);

% Plot the vessel:
figure()
plot3(vtuStruct.points(1:skip:end,1),...
      vtuStruct.points(1:skip:end,2),...
      vtuStruct.points(1:skip:end,3),'.');
xlabel('X (m)')
ylabel('Z (m)')
zlabel('Z (m)')
title('Vessel mesh vertices')

%--------------------------------------------------------------------------
% ODE solver options
%--------------------------------------------------------------------------

maxStep = get_step_size(vtuStruct, velocityPercentile, stepTolerance);
options.MaxStep = maxStep;
save(GeometryPropertiesPath,'options',"-append") % Do not modify
options = odeset(options,'Events',@(t,y)exitVesselFcn(t,y,Grid));

vtuStruct.velocities = -vtuStruct.velocities; % Backpropagate

% Function handle to the ODE:
odefun = @(t,y) transpose(...
    get_velocity(transpose(y), Grid, vtuStruct.velocities));

%==========================================================================
% BACKPROPAGATE STREAMLINES TOWARDS THE INLET
%==========================================================================

points_start = zeros(Nstreamlines,3); % Array for streamline start points.
points_end   = zeros(Nstreamlines,3); % Array for streamline end points.
end_velocity = zeros(Nstreamlines,3); % Array for end flow velocities.
t_end        = zeros(Nstreamlines,1); % Array for streamline end times.

t1 = tic;

if useparfor == true
    
    %----------------------------------------------------------------------
    % PARALLEL COMPUTING OF STREAMLINES
    %----------------------------------------------------------------------
    
    point_start_cell  = cell(1,Nstreamlines);
    points_end_cell   = cell(1,Nstreamlines);
    end_velocity_cell = cell(1,Nstreamlines);
    t_end_cell        = cell(1,Nstreamlines);

    parfor k = 1:Nstreamlines

        disp(['Computing streamline ' num2str(k) ' of ' ...
            num2str(Nstreamlines) '.'])

        % Position the bubble in the bulk of the vessel:
        startPosition = draw_start_position(1, vtuStruct);
        tspan = [0 Tmax];

        %------------------------------------------------------------------
        % COMPUTE STREAMLINE
        %------------------------------------------------------------------

        [t,positions] = ode23(odefun, tspan, startPosition(:),options);

        % Store the start point, end point, end velocity, and end time of
        % the streamline:
        point_start_cell{k} = startPosition(:);
        points_end_cell{k} = positions(end,:);
        end_velocity_cell{k} = get_end_velocity(positions,t);
        t_end_cell{k} = t(end);

    end

    % Assign the values in the cells to the matrices:
    for k = 1:Nstreamlines
        points_start(k,:) = point_start_cell{k};
        points_end(k,:)   = points_end_cell{k};
        end_velocity(k,:) = end_velocity_cell{k};
        t_end(k) = t_end_cell{k};
    end
        
else
    
    %----------------------------------------------------------------------
    % SERIAL COMPUTING OF STREAMLINES
    %----------------------------------------------------------------------
    
    figure()

    for k = 1:Nstreamlines

        disp(['Computing streamline ' num2str(k) ' of ' ...
            num2str(Nstreamlines) '.'])

        % Position the bubble in the bulk of the vessel:
        startPosition = draw_start_position(1, vtuStruct);
        tspan = [0 Tmax];

        %------------------------------------------------------------------
        % COMPUTE STREAMLINE
        %------------------------------------------------------------------

        [t,positions] = ode23(odefun, tspan, startPosition(:),options);

        %------------------------------------------------------------------
        % PLOT STREAMLINE
        %------------------------------------------------------------------
        plot3(positions(:,1),positions(:,2),positions(:,3));
        xlabel('X (m)')
        ylabel('Y (m)')
        zlabel('Z (m)')
        title('Streamlines')
        hold on
        drawnow

        % Store the start point, end point, end velocity, and end time of
        % the streamline:
        points_start(k,:) = startPosition(:);
        points_end(k,:)   = positions(end,:);
        end_velocity(k,:) = get_end_velocity(positions,t);
        t_end(k) = t(end);

    end  

end

toc(t1)
hold off

%--------------------------------------------------------------------------
% PLOT STREAMLINE START POINTS
%--------------------------------------------------------------------------
figure()
plot3(points_start(:,1),points_start(:,2),points_start(:,3),'r.');
xlabel('X (m)')
ylabel('Y (m)')
zlabel('Z (m)')
title('Streamline start points')
hold on

%==========================================================================
% PLOT AND SAVE RESULTS
%==========================================================================
points = points_end;

figure();
plot3(points(:,1),points(:,2),points(:,3),'.');
xlabel('X (m)')
ylabel('Z (m)')
zlabel('Z (m)')
title('Streamline end points')

save(fullfile(pathname, 'backpropagation_points.mat'),...
    'points','t_end','Tmax','end_velocity');

%==========================================================================
% FUNCTIONS
%==========================================================================

function v = get_end_velocity(points,t)
% Estimate the end velocity vector for a streamline represented by a set of
% points (N-by-3 array). Assign a velocity of zero if there is only one
% point.

if length(t)>1
    v = points(end,:) - points(end-1,:);
    v = v/(t(end) - t(end-1));
else
    v = zeros(1,3);
end

end