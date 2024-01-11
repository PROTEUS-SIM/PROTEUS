function Transducer = get_transducer_integration_points(...
    Transducer, Transmit, Medium, Grid)

% Grid coordinates:
gc.z = Grid.z;
c    = Medium.SpeedOfSound;	% [m/s]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PHYSICAL PROPERTIES OF THE TRANSDUCER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

N = Transducer.NumberOfElements;
p = Transducer.Pitch;
w = Transducer.ElementWidth;
f = Transducer.ElevationFocus;

W = (N-1)*p + w;                % Transducer width
H = Transducer.ElementHeight;   % Transducer height

y_min = -W/2 + (0:(N-1))*p;     % Left boundaries of transducer elements

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROPERTIES OF THE INTEGRATION POINT DISTRIBUTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Target integration point density in lateral dimension.
target_density = 1;   

% Number of integration points per element in lateral direction:
N_int_y = ceil(target_density*w/Grid.dy);

% Number of integration points per element in the elevation direction:
N_int_z = length(gc.z(gc.z>-H/2 & gc.z < H/2));

% Total number of integration points per element:
N_int = N_int_y*N_int_z;

% Integration point spacing in lateral direction:
spacing_int_y = w/N_int_y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET THE INTEGRATION POINTS FOR EACH ELEMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Matrix for holding the transducer integration points:
Transducer.integration_points      = zeros(N,N_int,3);

for i = 1:N
    % Coordinates of the integration points in the current element:
    x = 0;
    y = y_min(i) + (1:N_int_y)*spacing_int_y - spacing_int_y/2;
    z = gc.z(gc.z>-H/2 & gc.z < H/2);
    
    [x,y,z] = ndgrid(x,y,z);
    Transducer.integration_points(i,:,:) = [x(:) y(:) z(:)]; 
    
end

% Quadrature weight for each integration point:
Transducer.integration_weights = spacing_int_y/Grid.dy;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% APODIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Transducer.integration_transmit_apodization = zeros(N,N_int);

for i = 1:N
    
    % Apodization window in elevation direction (0 Rectangular window,
    % 1 Hann window):
    apodization_Z = false;
    if apodization_Z == true
        apod_winZ = getWin(N_int_z, 'Tukey', 'Param', 0.5, 'Plot', false); 
    else
        apod_winZ = ones(N_int_z,1);
    end
    
    apod_winZ = repmat(apod_winZ',N_int_y,1);
    
    % Multiply elevation apodization by electronic apodization:
    Transducer.integration_transmit_apodization(i,:) = ...
        Transmit.Apodization(i)*apod_winZ(:);
    
    % Receive apodization:
    Transducer.integration_receive_apodization(i,:) = apod_winZ(:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE DELAYS FOR EACH INTEGRATION POINT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Matrix for holding the delays:
Transducer.integration_transmit_delays = zeros(N,N_int);
Transducer.integration_receive_delays  = zeros(N,N_int);

for i = 1:N
    
    z = Transducer.integration_points(i,:,3);
    
    if abs(f)<Inf
        % Focused 
        delays = sqrt(z.^2 + f^2)/c;

        % Reverse time for positive focus:
        if f > 0
            delays = -delays;
        end
    else
        % Unfocused
        delays = z*0;
    end

    % Make all delays nonnegative:
    delays = delays - min(delays);
    
    % Add electronic delays:
    Transducer.integration_transmit_delays(i,:) = ...
        delays + Transmit.Delays(i) ;
    
    % Receive delays:
    Transducer.integration_receive_delays(i,:) = delays;
    
end

end

