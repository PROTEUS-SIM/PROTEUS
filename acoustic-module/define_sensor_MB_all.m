function [sensor, MB_idx_all, max_mb] = define_sensor_MB_all(...
    Grid, folder, Acquisition, N_sequence, Geometry)
%DEFINE_SENSOR_MB_ALL loops through all the frames and sequence pulses that
%need to be simulated and adds all corresponding microbubbles to the sensor
%struct for the first iteration.
%
% Grid:        Grid properties
% folder:      folder containing ground truth microbubble positions
% Acquisition: Acquisition properties
% N_sequence:  Number of pulses in each acquisition sequence
% Geometry:    Geometry properties
%
% Nathan Blanken, Alina Kuliesh, Guillaume Lajoinie, 2023

frame_start = Acquisition.StartFrame;     % First frame to include
frame_end   = Acquisition.EndFrame;       % Last frame to include
Nframes     = Acquisition.NumberOfFrames; % Total number of ground truth frames

sensor.mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz);
max_mb = 1;

for frame = frame_start : frame_end
       
    for pulse_seq_idx = 1:N_sequence
    
        MB = load_microbubbles(folder, frame, pulse_seq_idx, Geometry, Nframes);

        % Put the microbubbles on the grid:
        [MB.points, ~, MB_idx, ~] = voxelize_media_points(MB.points, Grid);
        
        if size(MB.points, 1) > max_mb
            max_mb = size(MB.points, 1);
        end

        % Put sensor at the microbubbles
        mask_only = true;
        [sensor,~] = update_sensor(sensor, MB.points, MB_idx, ...
            Grid, mask_only);
    
    end

    
end

sensor.record={'p'};
MB_idx_all = find(sensor.mask == 1);

end