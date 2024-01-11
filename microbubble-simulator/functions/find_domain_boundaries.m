function [A_m1,A_m2] =  find_domain_boundaries(coeff)
% Find domain boundaries for which the fit is valid.
% Segers et al, Soft Matter, 14, 2018. gives
% A_m1 = 0.92
% A_m2 = 1.12
% The precision of these number is low. This function finds
% higher-precision values for A_m1 and A_m2.

% Low-precision values from Segers et al, Soft Matter, 14, 2018.
A_m1 = 0.92;
A_m2 = 1.12;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LEFT BOUNDARY
% Find the left boundary for which the fit is valid. This is the point
% where the fit crosses zero.
R = roots(coeff);

% Exclude imaginary roots from the search.
R = R(imag(R)==0);

% Find the root closest to the low-precision value of A1.
[~,I] = min(abs(R-A_m1));
A_m1 = R(I);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RIGHT BOUNDARY
% Find the right boundary for which the fit is valid. For no real number,
% the fit reaches sig = 0.072, the surface tension of water. Therefore, we
% find the maximum of the fit.

% Local extrema:
R = roots(polyder(coeff));

% Exclude imaginary roots from the search.
R = R(imag(R)==0);

% Find the root closest to the low-precision value of A2.
[~,I] = min(abs(R-A_m2));
A_m2 = R(I);

end