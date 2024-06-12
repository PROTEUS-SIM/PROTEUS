function [R,P] = compute_polydisperse_distribution()
% Polydisperse size distribution of BR-14, see:
%
% N. Blanken, J. M. Wolterink, H. Delingette, C. Brune, M. Versluis and 
% G. Lajoinie, Super-Resolved Microbubble Localization in Single-Channel 
% Ultrasound RF Signals Using Deep Learning, in IEEE Transactions on 
% Medical Imaging, doi: 10.1109/TMI.2022.3166443.
%
% This is a fit to the experimental data in:
%
% Segers, Tim, et al. "Monodisperse versus polydisperse ultrasound contrast
% agents: Non-linear response, sensitivity, and deep tissue imaging 
% potential." Ultrasound Med. Biol. 44(7), 2018, 1482-1492.
%
% Only consider microbubbles between 0.5 um and 6 um. Microbubble behaviour
% uncertain outside this range.
%
% Nathan Blanken, University of Twente, 2022

N = 1e3;                            % Number of of points in distribution
Rmin = 0.5;                         % Minimum radius (um)
Rmax = 6;                           % Maximum radius (um)
R = linspace(Rmin,Rmax,N+1);    	% Radii (um)
a = 2.19;
P = R.^2.*exp(-a*R);                % Size distribution
P = P/sum(P);                       % Normalize size distribution
R = R*1e-6;                         % Radii (m)

end