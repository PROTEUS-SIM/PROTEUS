function source = define_source_transducer(Transducer, Transmit, ...
    Medium, Grid, source_weights, source_mask_idx)
% =========================================================================
% DEFINE THE TRANSDUCER SOURCE: add point sources to the source object
%
% input:    Transducer
%           Transmit
%           Medium
%           kgrid
%
% output:   source                  the transducer source object
% =========================================================================

delays  = Transducer.integration_transmit_delays;
apod    = Transducer.integration_transmit_apodization;
weights = Transducer.integration_weights;

% Apply electronic delays:
delays = delays + transpose(Transmit.Delays);

% Apply electronic apodization:
apod   = apod.*transpose(Transmit.Apodization);

% Pulsing scheme
switch Transmit.SeqPulse
    case 'even'
        apod(1:2:end, :) = 0;
    case 'odd'
        apod(2:2:end, :) = 0;
    case 'minus'
        apod = -apod;
end

delays  = delays(:);
apod    = apod(:);
weights = weights(:);

% Acoustic impedance:    
Z = Medium.SpeedOfSound*Medium.Density;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATE THE SOURCE MASK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

source.u_mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz, 'logical');
source.u_mask(source_mask_idx) = 1;


% Compute signal length required to apply the delays:
M = length(Transmit.PressureSignal);
N = M + ceil(max(delays)/Grid.dt);

% Convert pressure source to velocity source and apply delay and
% apodization.
velocity_source = Transmit.PressureSignal.*apod/Z;

% Set up frequency axis (Hz)
f = (0:(N-1))/(N*Grid.dt);

% Make symmetric around N/2 to keep time-domain signal real:
f(:,ceil(N/2+1):N) = -(f(:,floor(1+N/2):-1:2));

% Time shift in the frequency domain:
velocity_source = fft(velocity_source,N,2);
velocity_source = velocity_source.*exp(-2*pi*1i*delays*f);
velocity_source = ifft(velocity_source,[],2,'symmetric');

% Multiply the spatial delta function with the velocity source signals of 
% point sources.
source.ux = source_weights * (velocity_source.*weights);

end