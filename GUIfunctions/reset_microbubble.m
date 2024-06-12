function Microbubble = reset_microbubble()

Microbubble.Type            = 'SonoVue';
Microbubble.Number          = 10;

Microbubble.Advanced        = false;
Microbubble.Gas.Type    	= 'Sulfur hexafluoride';
Microbubble.Gas             = get_gas_properties(Microbubble.Gas);

% Select a thermal model: 'Adiabatic', 'Isothermal', or 'Propsperetti':
Microbubble.ThermalModel    = 'Prosperetti';

% Set the sampling rate [Hz] for the microbubble module:
Microbubble.SamplingRate    = 250e6;

% For Gaussian distribution only:
Microbubble.Distribution.MeanRadius      = 2.14e-6;  % (m)
Microbubble.Distribution.PDI             = 5;        % (%)


% Default: SonoVue distribution:
[R,P] = compute_polydisperse_distribution();

Microbubble.Distribution.Radii       	= R;    % Radii of distribution
Microbubble.Distribution.Probabilities 	= P;    % Probabilities of 
                                                % distribution

% Typical value intial surface tension: Sijl et al., J. Acoust. Soc. Am.,
% 129, 1729 (2011)

% Shell elasticity: Marmottant et al., J. Acoust. Soc. Am. 118 6, December 
% 2005

Microbubble.Shell.Model                 = 'Marmottant';
Microbubble.Shell.Elasticity            = 0.56;             % (N/m)
Microbubble.Shell.InitialSurfaceTension = 0.010;            % (N/m)
Microbubble.Shell.Viscosity             = 1e-8;             % (kg/s)

% For experimental surface tension curves. The fit has already been 
% evaluated for a predefined array A_m of normalised surface areas. The fit
% was evaluated with makeSegersArray.m.
%
% Fit from: Segers et al., Soft Matter, 2018, 14, 9550-9561

Microbubble.Shell.FitFileSegers         = 'fit_SigmaR_evaluated.mat';
Microbubble.Shell.FitFile               = [];

end