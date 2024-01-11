% Create an array with precomputed values of the surface tension curve from
% Segers et al., Soft Matter, 2018, 14, 9550-9561.

% Load the fit to the experimental surface tension curves. These are 
% the fit coefficients from the polynomial fit from Segers et al, Soft 
% Matter, 14, 2018. The fit coefficients printed in the article do not 
% have sufficient precision to reproduce the curve. Below are the 
% double-precision values obtained from Tim Segers.

clear
fit = load('fit_SigmaR_04-08-2017.mat');

% Get the domain boundaries of the fit:
[A_m1,A_m2] =  find_domain_boundaries(fit.fit.coeff);

sig_l = 0.072;                  % Surface tension water (N/m)

% Create a normalised surface area area:
dA_m = 0.002;
A_m = 0.91:dA_m:1.12; 

% Computing the surface tension directly from the fit gives a noisy curve
% which does not increase monotonically over the entire domeain.
% First compute the derivate and integrate for a smoother curve:

% Compute the derivative of the surface tension curve:
sigdiff = polyval(polyder(fit.fit.coeff),A_m);

sigdiff(A_m<A_m1) = 0;       	% Buckling
sigdiff(A_m>A_m2) = 0;          % Rupture

% Numerically integrate the derivative to get the surface tension:
sig = cumtrapz(sigdiff)*dA_m; 

% After integration, the maximum surface tension is marginally smaller than
% the surface tension of water. Rescale to compensate:
sig = sig/max(sig)*sig_l;

% Cut off constant parts in the surface tension curve:
I_min = find(sig==0,1,'last');  % Start index
I_max = find(sig==sig_l,1);     % End index
A_m = A_m(I_min:I_max);
sig = sig(I_min:I_max);

plot(A_m,sig)
xlabel('Normalised surface area')
ylabel('Surface tension (N/m)')

save('fit_SigmaR_evaluated.mat','A_m','sig')