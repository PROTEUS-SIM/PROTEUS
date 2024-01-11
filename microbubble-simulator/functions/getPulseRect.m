function pulse = getPulseRect(f,Ncy,PA,Fs,T,phi)
% Get an Ncy-cycle pulse with a rectangular window.

pulse.f = f;                % Centre frequency(Hz)
pulse.w = 2*pi*pulse.f;     % Angular centre frequency (Hz)

pulse.Nc = Ncy;             % Number of cycles
pulse.A = PA;               % Acoustic pressure amplitude (Pa)
pulse.fs = Fs;              % Sample frequency (Hz)

pulse.t = 0:1/pulse.fs:T;   % Time vector (s)

% Compute the acoustic pressure pulse:
pulse.p = PA*cos(2*pi*f*pulse.t + phi);
pulse.p(round(Ncy*Fs/f):end) = 0;   % Limit to Ncy cycles

end