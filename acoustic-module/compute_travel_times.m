function run_param = compute_travel_times(run_param, ...
    Geometry,Medium,Transducer,Transmit)

c  = Medium.SpeedOfSound;
fs = Transmit.SamplingRate;

% Compute maximum transmit and receive times to and from the boundary of
% the domain.
if isfield(Transducer,'Configuration') && ...
        ~strcmp(Transducer.Configuration,'Linear')
    
    d = find_max_distance_domain_boundary(Transducer,Geometry);
    transmit_time = d/c + Transducer.integration_transmit_delays;
    transmit_time = transmit_time + transpose(Transmit.Delays);
    transmit_time = max(transmit_time(:));

    receive_time  = d/c + Transducer.integration_receive_delays;
    receive_time  = max(receive_time(:));
else
    % Linear transducer configuration
    
    D = Geometry.Domain;

    % Centre of transducer elements [m]:
    y = Transducer.integration_points(:,:,2);
    y = transpose(mean(y,2));

    % Left and right boundaries of the transducer:
    y1 = max(Transducer.integration_points(:,:,2),[],'all');
    y2 = min(Transducer.integration_points(:,:,2),[],'all');

    % Distance to the bottom left corner of the domain from element center
    max_trans_dist1 = hypot((y - D.Ymin), D.Xmax);

    % Distance to the bottom right corner of the domain from element center
    max_trans_dist2 = hypot((y - D.Ymax), D.Xmax);

    max_trans_dist = max(max_trans_dist1,max_trans_dist2); % [m]

    transmit_time = max_trans_dist/c + Transmit.Delays;    % [s]
    transmit_time = max(transmit_time);

    max_rec_dist1 = hypot((y1 - D.Ymin), D.Xmax);
    max_rec_dist2 = hypot((y2 - D.Ymax), D.Xmax);
    receive_time  = max(max_rec_dist1,max_rec_dist2)/c;
    
end

max_mb_dist = norm(Geometry.BoundingBox.Diagonal); % [m]

% define simulation time for 1 & 3 iterations
N = length(Transmit.PressureSignal);
pulse_duration = (N-1)/fs; % [s]        
t_end_1 = 2*pulse_duration + transmit_time;                 % [s]
t_end_2 = 2*pulse_duration + transmit_time + max_mb_dist/c; % [s]
t_end_3 = 2*pulse_duration + transmit_time + receive_time;  % [s]

run_param.tr             = [t_end_1 t_end_2 t_end_3];
run_param.pulse_length   = c*pulse_duration;
run_param.max_trans_dist = transmit_time*c;

end

function d = find_max_distance_domain_boundary(Transducer,Geometry)
% Compute the maximum distance from each transducer integration point to
% the domain boundary.

N_el  = size(Transducer.integration_points,1); % Number of elements
N_int = size(Transducer.integration_points,2); % Number of integr. points
N_dim = size(Transducer.integration_points,3); % Number of dimensions (3)
N_V   = size(Geometry.Domain.Vertices,1); % Number of domain vertices (8)   

points1 = reshape(Transducer.integration_points,[N_el N_int 1   N_dim]);
points2 = reshape(Geometry.Domain.Vertices,     [1    1     N_V N_dim]);

d = vecnorm(points1 - points2,2,4); % N_el-by-N_int-by-N_V
d = max(d,[],3);                    % N_el-by-N_int

end