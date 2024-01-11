function Transmit = reset_transmit(Transducer)

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

Transmit.DelayType          = 'Compute delays';
Transmit.ApodizationType    = 'Uniform apodization';

Transmit.SignalsDefined     = true;

end