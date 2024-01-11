function pulse = getPulseHann(f,Ncy,PA,Fs,T,phi)
% Get an Ncy-cycle pulse with a Hann window.

pulse.f = f;                % Centre frequency(Hz)
pulse.w = 2*pi*pulse.f;     % Angular centre frequency (Hz)

pulse.Nc = Ncy;             % Number of cycles
pulse.A = PA;               % Acoustic pressure amplitude (Pa)
pulse.fs = Fs;              % Sample frequency (Hz)

pulse.t = 0:1/pulse.fs:T;   % Time vector (s)

% Compute the acoustic pressure pulse:
pulse.p = PA*cos(2*pi*f*pulse.t + phi).*sin(2*pi*f*pulse.t/Ncy/2).^2;
pulse.p(round(Ncy*Fs/f+1):end) = 0;   % Limit to Ncy cycles

% Compute the time-derivative of the acoustic pressure pulse:
pulse.dp = ...
    -PA*2*pi*f*sin(2*pi*f*pulse.t + phi).*sin(2*pi*f*pulse.t/Ncy/2).^2 ...
    +PA*cos(2*pi*f*pulse.t + phi).*(2*pi*f/Ncy/2).*sin(2*pi*f*pulse.t/Ncy);
pulse.dp(round(Ncy*Fs/f+1):end) = 0;  % Limit to Ncy cycles

end