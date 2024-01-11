function Transmit = get_voltage_signal(Transmit)
% Get the voltage signal driving the transducer.

switch Transmit.Type
    case 'Three-level'
        Transmit.VoltageSignal = get_tri_level_signal(Transmit);
    case 'Cosine envelope'
        switch Transmit.Envelope
            case 'Rectangular'
                phi = -pi/2;
                Transmit.VoltageSignal = get_rect_pulse(Transmit,phi);
            case 'Hann'
                phi = -pi/2;
                Transmit.VoltageSignal = get_hann_pulse(Transmit,phi);
        end
end

% If the user sets the voltage amplitude, scale the voltage curve
% accordingly.
if strcmp(Transmit.AmplitudeMode,'Voltage')
    V = Transmit.VoltageSignal;
    Transmit.VoltageSignal = V*(Transmit.VoltageAmplitude/max(V));
end

end

function V = get_tri_level_signal(Transmit)
% Get a pulse train of alternating positive and negative block 
% pulses, with Ncy cycles and frequency f at sampling rate Fs.

Fs = Transmit.SamplingRate;         % [Hz]
f = Transmit.CenterFrequency;       % Centre frequency(Hz)
Ncy = Transmit.NumberOfCycles;      % Number of cycles

ON_Frac = 0.67;                 % Fraction of half cycle with high level

N = round(Fs/f*Ncy);            % Total signal length

% A sine wave is ON_frac of a half cycle above V_th:
V = sin(2*pi*f*(0:(N-1))/Fs);  
V_th = sin((1-ON_Frac)*pi/2);

% Convert sine wave to tri-level signal.
V(V>=V_th)       = 1;
V(V<=-V_th)      = -1;
V(abs(V)<V_th) = 0;

end

function V = get_rect_pulse(Transmit,phi)
% Get an Ncy-cycle pulse with a rectangular window.

Fs = Transmit.SamplingRate;         % Sampling rate [Hz]
f = Transmit.CenterFrequency;       % Centre frequency [Hz]
Ncy = Transmit.NumberOfCycles;      % Number of cycles

N = round(Ncy*Fs/f);                % Total number of samples
t = (0:(N-1))/Fs;                   % Time vector [s]

% Compute the acoustic pressure pulse:
V = cos(2*pi*f*t + phi);

end

function V = get_hann_pulse(Transmit,phi)
% Get an Ncy-cycle pulse with a Hann window.

Fs = Transmit.SamplingRate;         % Sampling rate [Hz]
f = Transmit.CenterFrequency;       % Centre frequency(Hz)
Ncy = Transmit.NumberOfCycles;      % Number of cycles
N = round(Ncy*Fs/f);                % Total number of samples
t = (0:(N-1))/Fs;                   % Time vector (s)

% Compute the signal:
V = cos(2*pi*f*t + phi).*sin(2*pi*f*t/Ncy/2).^2;

end
