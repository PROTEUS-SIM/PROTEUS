function Transducer = get_transducer_integration_delays(Transducer, Medium)
% Compute lens delays for each transducer integration point

if isfield(Transducer,'Configuration') && ...
        strcmp(Transducer.Configuration,'RCA')
    
    delays = zeros(size(Transducer.integration_transmit_apodization));
    Transducer.integration_transmit_delays = delays;
    Transducer.integration_receive_delays  = delays;
    
elseif isfield(Transducer,'Configuration') && ...
        strcmp(Transducer.Configuration,'Custom')
    
    delays = zeros(size(Transducer.integration_transmit_apodization));
    if ~isfield(Transducer,'integration_transmit_delays')
        Transducer.integration_transmit_delays = delays;
    end
    if ~isfield(Transducer,'integration_receive_delays')
        Transducer.integration_receive_delays  = delays;
    end
else
    Transducer = compute_delays_linear_transducer(Transducer, Medium);
end

end

function Transducer = compute_delays_linear_transducer(Transducer, Medium)

f = Transducer.ElevationFocus;
 
z = Transducer.integration_points(:,:,3);

if isfinite(f)
    % Focused 
    delays = sqrt(z.^2 + f^2)/Medium.SpeedOfSound;

    % Reverse time for positive focus:
    if f > 0
        delays = -delays;
    end
else
    % Unfocused
    delays = z*0;
end

% Make all delays nonnegative:
delays = delays - min(delays(:));

% Transmit and receive delays:
Transducer.integration_transmit_delays = delays;
Transducer.integration_receive_delays  = delays;

end

