function Transducer = estimate_impulse_response(Transducer) 
% Butterworth filter approximation of transducer impulse response.
% Pass band (MHz) (-3 dB points)

% Nathan Blanken, University of Twente, 2021

passband = [Transducer.BandwidthLow Transducer.BandwidthHigh];

Fs = Transducer.SamplingRate/1e6;	% Sampling rate (MHz)
passband = passband / 1e6;          % Pass band (MHz) (-3 dB points)

df = passband(2) - passband(1);     % Bandwidth (MHz)
N = round(5*Fs/df);                 % Estimate of signal length


% Butterworth filter design:

% Third order butterworth filter gives a result that looks most like
% experimentally determined impulse response P4-1, with derivative zero at
% t = 0.

n = 3;                          % Order of butterworth filter
Wn = passband/(Fs/2);           % Normalized pass band
ftype = 'bandpass';             % Filter type

%
% Compute the filter coefficients:
[b,a] = butter(n,Wn,ftype);

% Compute the impulse response of the filter:
IR = impz(b,a,N,Fs)*Transducer.SamplingRate;

Transducer.TransmitImpulseResponse = IR';
Transducer.ReceiveImpulseResponse  = IR';

end