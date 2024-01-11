function main_RF(settingsfile, groundtruthfolder, savefolder, varargin)
% =========================================================================
% SIMULATE RF DATA
% input: settingsfile:      the file containing the simulation settings
%        groundtruthfolder: the folder containing the ground truth data
%        savefolder:        the folder to save the RF data
%        varargin{1}:       continue with the same k-Wave medium (boolean)
%        varargin{2}:       frame number to continue from (integer)
%        varargin{3}:       frame number to stop after (integer)
%        varargin{4}:       GPU device number (counting from zero)
%
% Alina Kuliesh,  Delft University of Technology
% Nathan Blanken, University of Twente
% 2022
% =========================================================================

% Get full paths and add modules to MATLAB path:
[settingsfile, groundtruthfolder, savedir] = ...
    sim_startup(settingsfile, groundtruthfolder, savefolder);

load(settingsfile,'Acquisition','Geometry','Medium',...
    'Microbubble','SimulationParameters', 'Transducer', 'Transmit')

% Process optional input arguments:
[Acquisition, SimulationParameters] = ...
    input_handling(Acquisition, SimulationParameters, varargin);

% simulation settings
run_param = sim_setup(SimulationParameters);

% Microbubble parallel processing properties:
Microbubble.BatchSize = run_param.MicrobubblesBatchSize;
Microbubble.UseParfor = run_param.MicrobubblesUseParfor;

% Location of the geometry data:
Geometry.GeometriesPath = run_param.GeometriesPath;

estimate = false;   % Estimate time and memory consumption
if ~isfield(Medium,'Save')
    Medium.Save = true; % Save the k-Wave medium
end

% Check if the microbubble properties and the acquisition properties for
% the ground truth data match the simulation properties:
check_ground_truth_data(groundtruthfolder,Acquisition,Microbubble,savedir)

disp(['RF data will be saved in: ' newline savedir '.' newline])

% Define the k-Wave grid:
disp('Creating k-Wave grid ...')
[kgrid, Grid] = define_grid(SimulationParameters, Geometry);

% Define the k-Wave medium:
if Acquisition.Continue
    disp('Loading k-Wave medium ...')
    load([savedir '/medium.mat'],'medium')
    Medium.Save = false; % No need to save the medium again
else
    disp('Creating k-Wave medium ...')
    [medium, vessel_grid] = define_medium(Grid, Medium, Geometry);
end

% Save the k-Wave medium
if Medium.Save
    disp('Saving k-Wave medium ...')
    save([savedir '/medium.mat'],'medium','vessel_grid','Grid','-v7.3')
end

% record signals long enough for back and forth pass of the wave
run_param = compute_travel_times(run_param, ...
    Geometry,Medium,Transducer,Transmit);

run_param.PML = Grid.PML;

% create the time array
kgrid.Nt = floor(run_param.tr(1) / kgrid.dt) + 1;

% Filter and resample transmit signal:
Transmit = preprocess_transmit(Transmit,Medium,kgrid);

% Distribute integration points at the transducer surface:
Transducer = get_transducer_integration_points(...
    Transducer, Transmit, Medium, Grid);

% Acquisition sequence
switch Acquisition.PulsingScheme
    case 'Amplitude modulation'
        sequence = {'odd' 'even' 'all'};
    case 'Pulse inversion'
        sequence = {'plus' 'minus'};
    case 'Standard'
        sequence = {'pulse'};
    case 'Amplitude modulation with pulse inversion'
        sequence = {'odd' 'even' 'minus'};
end

% define sensor
[sensor_MB_all, MB_idx_all, max_mb] = define_sensor_MB_all(...
    Grid, groundtruthfolder, Acquisition, length(sequence), Geometry);

%==========================================================================
% strucutre for time and memory estimation
param.c_max = Medium.SpeedOfSoundMaximum;
param.CFL = SimulationParameters.CFL;
param.tr = run_param.tr;
param.num_frames = Acquisition.EndFrame - Acquisition.StartFrame + 1;
param.num_pulse = Acquisition.NumberOfPulses;
param.num_int = SimulationParameters.NumberOfInteractions;
param.max_mb = max_mb;
param.PML = Grid.PML;

%==========================================================================
% First iteration: transducer send pulse; MBs record pulse

disp('Creating k-Wave sensor object for transducer.')
[sensor_transducer, sensor_weights] = define_sensor_transducer(...
    Transducer, Grid);

mask_idx_trans = find(logical(sensor_transducer.mask));

if ~isempty(intersect(MB_idx_all, mask_idx_trans))
    warning('Microbubbles on transducer.')
end

if SimulationParameters.HybridSimulation
    % Add the two sensor masks:
    sensor.mask = logical(sensor_MB_all.mask + sensor_transducer.mask);
    sensor.record = sensor_MB_all.record;

    % Record sufficiently long for a round trip:
    kgrid.Nt = floor(run_param.tr(3) / kgrid.dt) + 1;
else
    sensor = sensor_MB_all;
    kgrid.Nt = floor(run_param.tr(1) / kgrid.dt) + 1;
end

source_transducer = cell(1,length(sequence));
sensor_data_1iter = cell(1,length(sequence));

for pulse_seq_idx = 1 : length(sequence)

    Transmit.SeqPulse = sequence{pulse_seq_idx};

    % define the transducer source
    disp('Creating k-Wave source object for transducer.')   
    source_transducer{pulse_seq_idx} = define_source_transducer(...
        Transducer, Transmit, Medium, Grid, transpose(sensor_weights), ...
        mask_idx_trans);

    % Simulation time and memory estimation:
    if pulse_seq_idx == 1 && estimate == true
        beta_coeff_file = ['time-estimation' filesep 'beta_coeff.mat'];
        estim_time_mem(Grid, source_transducer{pulse_seq_idx}, param, ...
            beta_coeff_file);
    end

    disp('Simulating transmit wave.')
    
    sensor_data_1iter{pulse_seq_idx} = run_simulation(run_param, kgrid, ...
        medium, source_transducer{pulse_seq_idx}, sensor);
end

%==========================================================================
% Second & Third iterations

% Start time and array for holding execution times for performance
% quantification:
tstart = tic;
execution_times = zeros(1,Acquisition.NumberOfFrames);
saveExecutionTimes = false;

for frame = Acquisition.StartFrame : Acquisition.EndFrame
    display(['frame ', num2str(frame)])
    
    RF = cell(1,length(sequence));
    Frame = cell(1,length(sequence));
    
    for pulse_seq_idx = 1 : length(sequence)
        
        MB = load_microbubbles(groundtruthfolder, frame, pulse_seq_idx, Geometry, ...
            Acquisition.NumberOfFrames);
        
        % define the sensor of the current frame
        [sensor_frame, sensor_weights_frame, MB, run_param.max_dist] = ...
            define_sensor_MB(Grid, MB);
        
        mask_idx       = find(logical(sensor.mask));
        mask_idx_frame = find(logical(sensor_frame.mask));
        
        % Split sensor data into microbubble sensor data and transducer
        % sensor data.
        [sensor_data_MB, sensor_data_trans] = extract_sensor_data(...
            sensor_data_1iter{pulse_seq_idx}, ...
            mask_idx, mask_idx_trans, mask_idx_frame, run_param, kgrid);
        
        % Pressure sensed by the microbubbles
        sensed_p = sensor_weights_frame*double(sensor_data_MB.p);
        sensed_p = cast(full(sensed_p),class(sensor_data_MB.p));
        
        % Complete the transducer sensor data with microbubble sources:
        if SimulationParameters.HybridSimulation
            
            sensor_data = hybrid_simulator(...
                mask_idx_trans,...
                sensed_p, ...
                MB, Grid, medium, run_param, ...
                Medium, Microbubble, Transmit);

            % Update sensor data transducer:
            sensor_data.p = sensor_data_trans.p + sensor_data.p;
            
        else
            
            sensor_data = full_simulator(...
                source_transducer{pulse_seq_idx}, ...
                sensor_transducer,...
                sensor_frame,sensor_weights_frame,mask_idx_frame,...
                sensed_p,...
                MB, kgrid, Grid, medium, run_param, ...
                Medium, Microbubble, Transmit);
            
        end
        
        % Compute element RF data recorded by transducer:
        [RF{pulse_seq_idx}, run_param] = compute_RF_data(...
            Transducer,sensor_data,sensor_weights,Grid,run_param);
        
        Frame{pulse_seq_idx} = MB;
        
    end
    
    % Save data
    dt = kgrid.dt;
    % Find out how many zero padding you'll need for file name
    num_padding=num2str(length(num2str(Acquisition.NumberOfFrames)));
    file_name = ['Frame_', num2str(frame,['%0',num_padding,'i']),'.mat'];
    save([savedir filesep file_name], 'RF', 'dt', 'Frame')
    
    execution_times(frame) = toc(tstart);
    
end

% Save execution times for performance quantification if requested:
if saveExecutionTimes == true
    file_name = 'execution_time_history.mat';
    save([savedir filesep file_name], 'execution_times')
end

end