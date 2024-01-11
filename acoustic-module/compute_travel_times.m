function run_param = compute_travel_times(run_param, ...
    Geometry,Medium,Transducer,Transmit)

c  = Medium.SpeedOfSound;
fs = Transmit.SamplingRate;

D = Geometry.Domain;

% Transducer properties
N = Transducer.NumberOfElements;
p = Transducer.Pitch;
w = Transducer.ElementWidth;
W = (N-1)*p + w;                % Transducer width

transmit_time = zeros(1,N);

for i = 1 : N
    % element offset from end left element of transducer
    el_offset = (i - 0.5) * p; % [m]
    
    % distance to the bottom left corner of the domain from element center
    max_trans_dist1 = hypot((-W/2 + el_offset - D.Ymin), D.Xmax); % [m]
    
    % distance to the bottom right corner of the domain from element center
    max_trans_dist2 = hypot((-W/2 + el_offset - D.Ymax), D.Xmax); % [m]
    
    max_trans_dist  = max(max_trans_dist1, max_trans_dist2);      % [m]
    transmit_time(i) = max_trans_dist / c + Transmit.Delays(i);   % [s]
end

max_rec_dist1 = hypot(( W/2 - D.Ymin), D.Xmax);
max_rec_dist2 = hypot((-W/2 - D.Ymax), D.Xmax);
max_rec_dist  = max(max_rec_dist1,max_rec_dist2);

max_mb_dist   = norm(Geometry.BoundingBox.Diagonal); % [m]

% define simulation time for 1 & 3 iterations
pulse_length = (length(Transmit.PressureSignal) - 1) * c/fs;          % [s]
t_end_1 = max(transmit_time) + 2 * pulse_length / c;                  % [s]
t_end_2 = max(transmit_time) + (max_mb_dist  + 2 * pulse_length) / c; % [s]
t_end_3 = max(transmit_time) + (max_rec_dist + 2 * pulse_length) / c; % [s]

max_trans_dist = max(transmit_time)*c;

run_param.tr             = [t_end_1 t_end_2 t_end_3];
run_param.pulse_length   = pulse_length;
run_param.max_trans_dist = max_trans_dist;

end