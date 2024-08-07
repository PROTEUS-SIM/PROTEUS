function Transmit = reset_transmit(Transducer)

if ~isfield(Transducer,'Configuration')
    Transducer.Configuration = 'Linear';
end

Transmit.Type               = 'Three-level';
Transmit.CenterFrequency    = Transducer.CenterFrequency;
Transmit.NumberOfCycles     = 2;
Transmit.AcousticPressure   = 200e3;            % [Pa]
Transmit.Envelope           = 'Rectangular';
Transmit.SamplingRate       = 250e6;            % [Hz]
Transmit.AmplitudeMode      = 'Pressure';
Transmit.VoltageAmplitude   = 1;                % [V]

Transmit = get_voltage_signal(Transmit);
Transmit = get_pressure_signal(Transmit,Transducer);

Transmit.Advanced           = false;
Transmit.LateralFocus       = Inf;              % [m]
Transmit.Angle              = 0;                % [deg]

Transmit.ApodizationType    = 'Uniform apodization';

Transmit.SignalsDefined     = true;

switch Transducer.Configuration
    case 'Linear'
        Transmit.DelayType  = 'Compute delays';
    case 'RCA'
        Transmit.DelayType  = 'No delays';
    case 'Custom'
        Transmit.DelayType  = 'No delays';
end

end