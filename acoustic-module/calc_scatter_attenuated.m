function ps = calc_scatter_attenuated(mass_source,medium,kgrid,r)
% Simulate the waveform at a distance r from the transducer for spherical
% wave transmission. Nonlinear propagation is neglected, considering the
% rapid decay of a spherical wave.
% 
% Based on Green's function approach in:
% James F. Kelly et al., Analytical time-domain Green’s functions for 
% power-law media, J. Acoust. Soc. Am, 124 (5), 2008.
% 
% and material transfer function approach in:
% T. L. Szabo, Diagnostic Ultrasound Imaging: Inside Out. Academic Press, 
% 2004, Second Edition, Chapter 4
%
% Nathan Blanken, University of Twente, 2022

Fs = 1/kgrid.dt; % Sampling frequency (Hz)

% MATERIAL PROPERTIES
% Speed of sound in the medium:
c0  = medium.c;         

% Scoustic attenuation parameters (a*f_MHz^b in Np/m)
a   = medium.a*log(10)*100/20;
b   = medium.b;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MASS SOURCE DERIVATIVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create symmetric frequency axis:
N = length(mass_source);
f = (0:(N-1))/N*Fs;
f(ceil(N/2+1):N) = -f(floor(1+N/2):-1:2);

% Compute the time-derivative of the mass source:
MS_dot = real(ifft(2i*pi*f.*fft(mass_source)));

% Make sure output signal has length kgrid.Nt:
MS_dot((N+1):kgrid.Nt) = 0;
MS_dot((kgrid.Nt+1):N) = [];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATERIAL TRANSFER FUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N = length(MS_dot);

% Use domain extension to prevent periodic wave wrapping:
N = N*2;

% Set up frequency axis (Hz)
f = (0:(N-1))/N*Fs;

% Compute attenuation as function of frequency
f_MHz = f/10^6;                % Frequency (MHz)
alpha = a*abs(f_MHz).^b;       % Attenuation (Np/m)

% Compute the dispersion as a function of frequency
c = powerLawKramersKronig(2*pi*f, 0, c0, db2neper(medium.a, b), b);

% No dispersion:
if isfield(medium,'alpha_mode') && ...
        strcmp(medium.alpha_mode, 'no_dispersion')
    c = c0;
end

% Compute the material transfer function:
W = exp(-r*alpha - 2*pi*1i*r*(f./c));

% Make symmetric around N/2 to keep time-domain signal real:
W(:,ceil(N/2+1):N) = conj(W(:,floor(1+N/2):-1:2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GREEN'S FUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Apply the material transfer function:
r(r==0) = Inf;  % Map self-interaction to 0 (source cannot sense itself)
scatterFFT = fft(MS_dot,N)./(4*pi*r);
ps = real(ifft(scatterFFT.*W,[],2));

% Crop to original domain size:
ps = ps(:,1:N/2);

end