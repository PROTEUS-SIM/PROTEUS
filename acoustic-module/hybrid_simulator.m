function sensor_data = hybrid_simulator(...
    sensor_mask_idx_trans, ...
    sensed_p_1iter,...
    MB, Grid, medium, run_param, ...
    Medium, Microbubble, Transmit)

t_end_1         = run_param.tr(1);
t_end_3         = run_param.tr(3);
max_trans_dist  = run_param.max_trans_dist;
max_dist        = run_param.max_dist;
pulse_length    = run_param.pulse_length;
N_interactions  = run_param.N_interactions;

% Add the microbubble module to the path
addpath(run_param.MicrobubblePath)
addpath(fullfile(run_param.MicrobubblePath,'functions'))

Nt = floor(t_end_1 / Grid.dt) + 1;

sensed_p = sensed_p_1iter;

% k_max only to be used in k-Wave function filterTimeSeries:
Grid.k_max = pi/Grid.dt/Medium.SpeedOfSoundMinimum;

for iter = 1:N_interactions

    display(['Simulating bubble-bubble interaction, '...
        'iteration ', num2str(iter)]);

    % create the time array
    t_end_2 = (max_trans_dist + max_dist  + 2*pulse_length) / ...
        Medium.SpeedOfSound; % [s]

    % Update number of time points:
    Grid.Nt = floor(t_end_2 / Grid.dt) + 1; 

    % Compute microbubble mass sources:       
    mass_source = compute_bubble_mass_source(...
        sensed_p,  MB.radii, Grid, Medium, Microbubble, Transmit);

    source = [];
    sensor = [];   

    source.mass_source  = mass_source;
    source.points       = MB.points;
    sensor.points       = MB.points;

    % Do not discretise the distances between source and sensors:
    run_param.gridded = false;

    % Run the linear simulation:
    sensor_data = run_simulation_homogeneous(...
        run_param, Grid, medium, source, sensor);

    % Transfer data to CPU if on GPU:
    sensor_data.p = gather(sensor_data.p);

    % Add the sensor data from the transducer:
    sensed_p(:,1:Nt) = sensor_data.p(:,1:Nt) + sensed_p_1iter;

end

disp('Simulating receive data.')

% Third iteration: transducer send & record pulse ; MBs send pulse

% Update number of time points:
Grid.Nt = floor(t_end_3 / Grid.dt) + 1;

% Compute microbubble mass sources:       
mass_source = compute_bubble_mass_source(...
    sensed_p,  MB.radii, Grid, Medium, Microbubble, Transmit);

[i,j,k] = ind2sub([Grid.Nx,Grid.Ny,Grid.Nz],...
    sensor_mask_idx_trans);

sensor.points = transpose([Grid.x(i); Grid.y(j); Grid.z(k)]);

source.mass_source  = mass_source;
source.points       = MB.points;

% Discretise the distances between source and sensors to reduce computation
% time:
run_param.gridded = true;

% Run the linear simulation:
sensor_data = run_simulation_homogeneous(...
    run_param, Grid, medium, source, sensor);

% Remove the microbubble module from the path
rmpath(run_param.MicrobubblePath)
rmpath(fullfile(run_param.MicrobubblePath,'functions'))

end