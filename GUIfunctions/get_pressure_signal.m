function Transmit = get_pressure_signal(Transmit,Transducer)

if strcmp(Transmit.Type,'Custom (pressure)')
    p = Transmit.PressureSignal;
else
    % Convolve driving voltage signal with transmit impulse response:
    V  = Transmit.VoltageSignal;
    IR = Transducer.TransmitImpulseResponse;
    p = conv(V, IR)/Transducer.SamplingRate;
end

% Peak negative pressure
pnp = abs(min(p));

switch Transmit.AmplitudeMode
    case 'Pressure'
        % Scale to desired peak negative pressure:
        p = p*(Transmit.AcousticPressure/pnp);
    case 'Voltage'
        Transmit.AcousticPressure = pnp;
end

Transmit.PressureSignal = p;

% Update the mechanical index
Transmit.MechanicalIndex = compute_mechanical_index(Transmit);

end


function MI = compute_mechanical_index(Transmit)

f = Transmit.CenterFrequency/1e6;   % (MHz)
P = Transmit.AcousticPressure/1e6;  % Peak negative pressure (MPa)
MI = P/sqrt(f);                     % Mechanical index

end