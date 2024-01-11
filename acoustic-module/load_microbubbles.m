function MB = load_microbubbles(...
    folder, frame, pulse_seq_idx, Geometry, num_frames)

unit_points   = 1;    % Length unit of the bubble locations [m]

% cells for each frame containing an array with the MBs coordinates on the 
% streamlines 

% Find out how many zero padding you'll need for file name:
num_padding=num2str(length(num2str(num_frames)));
load([folder, filesep, 'Frame_', ...
    num2str(frame,['%0',num_padding,'i']),'.mat'],'Frame');

% Get the microbubble properties for the specified pulse:
pulse = ['Pulse' num2str(pulse_seq_idx)];
Frame = Frame.(pulse);

% coordinates of the points in [m]
points = Frame.Points * unit_points; % [x(axial), y(long), z(elev)]

% points must be size 3xN
points = transpose(points);
    
% Centre the points at the origin:
points = points - Geometry.BoundingBox.Center; % [m]

% Rotate the points
points = Geometry.Rotation*points;

% Translate the points to the desired location:
points = points + Geometry.Center;

% return to original Nx3 format
MB.points = transpose(points);

% Radii of the microbubbles:
MB.radii = Frame.Radius;

% Microbubble velocities:
MB.velocities = Frame.Velocity;
MB.velocities = MB.velocities*transpose(Geometry.Rotation);

end