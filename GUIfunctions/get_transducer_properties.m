function Transducer = get_transducer_properties(Transducer)

switch Transducer.Type
    case 'P4-1'
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
        
        
    case 'L22-14v'
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
        
        
    case '9L-D'
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
        
    case 'RC6gV'
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

end

end


