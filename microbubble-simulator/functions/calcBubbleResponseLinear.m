function [response, eqparam, scatter] = calcBubbleResponseLinear(liquid, ...
    gas, shell, bubble, pulse)
% Compute the radial response and the scattered pressure of a microbubble,
% based on the the linearisation of the Rayeleigh-Plesset equation given in
% Marmottant et al., J. Acoust. Soc. Am. 118 6, 2005.
% Nathan Blanken, University of Twente, 2022.

rho     = liquid.rho;
c       = liquid.c;
Fs      = pulse.fs;
r       = bubble.r0;
R0      = bubble.R0;

eqparam = getEqParam(liquid, gas, shell, bubble, pulse);

N = length(pulse.p);        % Signal length
f = (0:(N-1))/N*Fs;         % Frequency vector
omega = 2*pi*f;             % Angular frequency vector

% Make symmetric around 0:
omega(ceil(N/2+1):N) = -omega(floor(1+N/2):-1:2);

% Resonance frequency and damping parameter:
omega_0 = eqparam.omega_0;
beta = eqparam.delta*omega_0;

% Bubble impulse response:
A = - 1/(rho*R0^2)./(omega_0^2 - omega.^2 + 1i*beta*omega);

% Compute radial and pressure response:
response.R = R0*(1 + real(ifft(fft(pulse.p).*A)));
response.Rdot = R0*real(ifft(fft(pulse.p).*A*1i.*omega));
response.t = pulse.t;

scatter.ps = -rho*R0^3/r*real(ifft(fft(pulse.p).*A.*omega.^2));
scatter.t  = pulse.t + r/c; 

end