function Transmit = compute_delays(Transmit,Transducer,Medium)

% Speed of sound:
c = Medium.SpeedOfSound;            % [m/s]

% Transmit properties:
f       = Transmit.LateralFocus;    % [m]
theta   = Transmit.Angle;           % [degrees]

% Compute transducer element positions
N = Transducer.NumberOfElements;
x = (-(N-1)/2:(N-1)/2)*Transducer.Pitch;

f_x = f*sind(theta);    % lateral component focal point [m]
f_y = f*cosd(theta);    % axial component focal point [m]

% Compute delays:
if abs(f)<Inf
    % Focused 
    delays = sqrt((f_x-x).^2 + f_y^2)/c;
    
    % Reverse time for positive focus:
    if f > 0
        delays = -delays;
    end
else
    % Unfocused
    delays = x*sind(theta)/c;
end

% Make all delays nonnegative:
Transmit.Delays = delays - min(delays);

end