function Transducer = reset_transducer()

Transducer.Type             = 'P4-1';

% Sets Transducer.ImpulseResponseType to 'Calibrated' (impulse responses
% from Transducer-models/P4-1.mat) or 'Estimate':
Transducer = get_transducer_properties(Transducer);

if strcmp(Transducer.ImpulseResponseType,'Estimate')
    % Set the sampling rate for the impulse responses:
    Transducer.SamplingRate = 250e6;    % [Hz]

    % Estimate the impulse response from the bandwidth:
    Transducer = estimate_impulse_response(Transducer);
end

end
