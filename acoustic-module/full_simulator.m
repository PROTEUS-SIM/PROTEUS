function sensor_data = full_simulator(...
    source, ...
    sensor_transducer,...
    sensor_frame, sensor_weights_frame, sensor_mask_idx_frame,...
    sensed_p,...
    MB, kgrid, Grid, medium, run_param, ...
    Medium, Microbubble, Transmit)

t_end_3         = run_param.tr(3);
max_trans_dist  = run_param.max_trans_dist;
max_dist        = run_param.max_dist;
pulse_length    = run_param.pulse_length;
N_interactions  = run_param.N_interactions;

% Add the microbubble module to the path
addpath(run_param.MicrobubblePath)
addpath(fullfile(run_param.MicrobubblePath,'functions'))

% Grid size for single-bubble simulations:
% (min 2 lambda between source and PML)
f0 = Transmit.CenterFrequency;
N_sup = ceil(2 * 2 * Medium.SpeedOfSound / f0 / Grid.dx); % [voxels]

for iter = 1:N_interactions

    display(['Simulating bubble-bubble interaction, '...
        'iteration ', num2str(iter)]);

    % create the time array
    t_end_2 = (max_trans_dist + max_dist  + 2*pulse_length) / ...
        Medium.SpeedOfSound; % [s]

    % Update t_array (array updates automatically):
    kgrid.Nt = floor(t_end_2 / kgrid.dt) + 1; 

    % Compute microbubble mass sources:       
    mass_source = compute_bubble_mass_source(...
        sensed_p,  MB.radii, kgrid, Medium, Microbubble, Transmit);

    % Add the microbubble mass sources to the source:           
    source = update_source(source, mass_source, ...
        transpose(sensor_weights_frame), sensor_mask_idx_frame, ...
        Grid, medium);

    % Run the k-Wave simulation:
    sensor_data = run_simulation(...
        run_param, kgrid, medium, source, sensor_frame);

    % Pressure sensed by the microbubbles:     
    sensed_p = sensor_weights_frame*double(sensor_data.p);
    sensed_p = cast(full(sensed_p), class(sensor_data.p));

    % Subtract the self-sensed pressure:
    self_sense_pressure = compute_self_sense_pressure(kgrid, ...
        Grid, MB.idx, MB.points, mass_source,...
        medium, N_sup, run_param);

    sensed_p = sensed_p - self_sense_pressure;

end

disp('Simulating receive data.')

% Third iteration: transducer send & record pulse ; MBs send pulse

% Update t_array (array updates automatically):
kgrid.Nt = floor(t_end_3 / kgrid.dt) + 1;

% Compute microbubble mass sources:       
mass_source = compute_bubble_mass_source(...
    sensed_p,  MB.radii, kgrid, Medium, Microbubble, Transmit);

% Add the microbubble mass sources to the source:       
source = update_source(source, mass_source, ...
    transpose(sensor_weights_frame), sensor_mask_idx_frame, Grid, medium);

sensor_data = run_simulation(...
    run_param, kgrid, medium, source, sensor_transducer);

% Remove the microbubble module from the path
rmpath(run_param.MicrobubblePath)
rmpath(fullfile(run_param.MicrobubblePath,'functions'))

end