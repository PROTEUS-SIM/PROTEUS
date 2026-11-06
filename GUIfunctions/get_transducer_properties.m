function Transducer = get_transducer_properties(Transducer)
%GET_TRANSDUCER_PROPERTIES Properties of the transducers in the catalogue.
%
% Transducer = GET_TRANSDUCER_PROPERTIES(Transducer) sets the properties
% of the transducer Transducer.Type. If a model file
% Transducer-models/<Type>.mat exists, its calibrated properties (impulse
% responses and, if present, geometry) take precedence over the values
% below. See load_transducer_model.

switch Transducer.Type
    case 'P4-1'
        Transducer.calibrated       = 0;
        Transducer.ImpulseResponseType = 'Estimate';
        Transducer.Configuration    = 'Linear';
        Transducer.NumberOfElements = 96;
        Transducer.Pitch            = 0.295e-3; % [m]
        Transducer.ElementWidth     = 0.245e-3; % [m]
        Transducer.ElementHeight   	= 16e-3;    % [m]
        Transducer.ElevationFocus   = 110e-3;   % [m]
        
        % Lower and upper -6 dB limit [Hz]:
        Transducer.BandwidthLow  	= 1.5e6;    % [Hz]
        Transducer.BandwidthHigh  	= 3.5e6;    % [Hz]
        Transducer.CenterFrequency  = 2.5e6;    % [Hz]
        Transducer.Radius           = 0;        % [m]
        
        
    case 'C1-6D'
        % Datasheet values. Transducer-models/C1-6D.mat (calibration)
        % takes precedence.
        Transducer.calibrated       = 0;
        Transducer.ImpulseResponseType = 'Estimate';
        Transducer.Configuration    = 'Curved';
        Transducer.NumberOfElements = 192;
        Transducer.Pitch            = 0.350e-3; % [m]
        Transducer.ElementWidth     = 0.340e-3; % [m]
        Transducer.ElementHeight    = 11.4e-3;  % [m]
        Transducer.ElevationFocus   = 72.7e-3;  % [m]

        % Lower and upper -6 dB limit [Hz]:
        Transducer.BandwidthLow     = 1.5e6;    % [Hz]
        Transducer.BandwidthHigh    = 5.5e6;    % [Hz]
        Transducer.CenterFrequency  = 3.4e6;    % [Hz]
        Transducer.Radius           = 56.8e-3;  % [m] radius of curvature

    case 'L22-14v'
        Transducer.calibrated       = 0;
        Transducer.ImpulseResponseType = 'Estimate';
        Transducer.Configuration    = 'Linear';
        Transducer.NumberOfElements = 128;
        Transducer.Pitch            = 100e-6;   % [m]
        Transducer.ElementWidth     = 80e-6;    % [m]
        Transducer.ElementHeight   	= 1.6e-3; 	% [m]
        Transducer.ElevationFocus   = 8e-3;     % [m]
        
        % Lower and upper -6 dB limit [Hz]:
        Transducer.BandwidthLow   	= 14e6;     % [Hz]
        Transducer.BandwidthHigh  	= 22e6;     % [Hz]
        Transducer.CenterFrequency  = 18e6;     % [Hz]
        Transducer.Radius           = 0;        % [m]
        
        
    case '9L-D'
        Transducer.calibrated       = 0;
        Transducer.ImpulseResponseType = 'Estimate';
        Transducer.Configuration    = 'Linear';
        Transducer.NumberOfElements = 192;
        Transducer.Pitch            = 0.23e-3;  % [m]
        Transducer.ElementWidth     = 0.21e-3;  % [m]
        Transducer.ElementHeight    = 6e-3; 	% [m]
        Transducer.ElevationFocus   = 28e-3;    % [m]
        
        % Lower and upper -6 dB limit [Hz]:
        Transducer.BandwidthLow     = 3.3e6;    % [Hz]
        Transducer.BandwidthHigh    = 7.3e6;    % [Hz]
        Transducer.CenterFrequency  = 5.3e6;    % [Hz]
        Transducer.Radius           = 0;        % [m]
        
    case 'RC6gV'
        Transducer.calibrated       = 0;
        Transducer.ImpulseResponseType = 'Estimate';
        Transducer.Configuration    = 'RCA';
        Transducer.NumberOfElements = 256;
        Transducer.Pitch            = 0.2e-3;   % [m]
        Transducer.ElementWidth     = 0.175e-3; % [m]
        Transducer.ElementHeight    = 0.025575; % [m]
        Transducer.ElevationFocus   = Inf;      % [m]
        
        % Lower and upper -6 dB limit [Hz]:
        Transducer.BandwidthLow     = 3e6;      % [Hz]
        Transducer.BandwidthHigh    = 9e6;      % [Hz]
        Transducer.CenterFrequency  = 6e6;      % [Hz]     
        Transducer.Radius           = 0;        % [m]

    case 'Custom linear'
        % User-defined linear array: keep the user's values, but not the
        % configuration or calibration of a previously selected type.
        Transducer.Configuration    = 'Linear';
        Transducer.Radius           = 0;        % [m]
        Transducer.calibrated       = 0;
        if isfield(Transducer,'ImpulseResponseType') && ...
                strcmp(Transducer.ImpulseResponseType,'Calibrated')
            % Keep the impulse responses as user-defined ones:
            Transducer.ImpulseResponseType = 'Load file';
        end

end

% Calibrated properties from the model file, if any:
Transducer = load_transducer_model(Transducer);

end
