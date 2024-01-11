function [R,P] = compute_gaussian_distribution(Microbubble)

R0 = Microbubble.Distribution.MeanRadius;

N = 1e3;                            % Number of of points in distribution
Rmin = 0.5e-6;                      % Minimum radius (m)
Rmax = 6e-6;                        % Maximum radius (m)

R = linspace(Rmin,Rmax,N);
sR = R0*Microbubble.Distribution.PDI/100;	% Standard deviation (m)
P = exp(-(R-R0).^2/(2*sR^2));               % Probability distribution
P = P/sum(P);                               % Normalize size distribution

end