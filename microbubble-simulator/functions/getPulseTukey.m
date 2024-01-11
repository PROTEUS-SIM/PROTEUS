function pulse = getPulseTukey(f,Ncy,PA,Fs,T,phi,Ncy_taper)
% Get an Ncy-cycle pulse with a cosine-tapered window.

pulse.f = f;                % Centre frequency(Hz)
pulse.w = 2*pi*pulse.f;     % Angular centre frequency (Hz)

pulse.Nc = Ncy;             % Number of cycles
pulse.A = PA;               % Acoustic pressure amplitude (Pa)
pulse.fs = Fs;              % Sample frequency (Hz)

pulse.t = 0:1/pulse.fs:T;   % Time vector (s)

N       = length(pulse.t);          % Total signal length
N_sig   = round(Ncy/f*Fs);          % Active signal length
N_taper = round(Ncy_taper/f*Fs); 	% Number of grid points in taper

% Construct the envelope:
env                         = ones(1,N);           
env(N_sig+1:end)            = 0;
env(1:N_taper)              = 1/2*(1-cos(pi*(0:(N_taper-1))/N_taper));
env(N_sig-N_taper+1:N_sig)  = 1/2*(1+cos(pi*(0:(N_taper-1))/N_taper));


% Compute the acoustic pressure pulse:
pulse.p = PA*cos(2*pi*f*pulse.t + phi).*env;

end