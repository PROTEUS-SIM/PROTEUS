function X = draw_random_radii(P,R,N)
%DRAW_RANDOM_RADII Draw N random numbers from a probability density 
%function P(R).
% N: number of microbubbles (an integer)
% P: probability distribution (row array)
% R: list of radii (row array)
% X: random radii 1-by-N array
%
% Nathan Blanken, University of Twente, 2023

% Display a warning if the sum of all probabilities is unequal to 1:
if (sum(P) - 1) > 0.01
    warning(['Sum of all probabilities unequal to 1. '...
        'Normalizing probability density function.'])
end

% Cumulative distribution
Pcdf = cumsum(P);
Pcdf = Pcdf - Pcdf(1); % To make sure that Pcdf starts from 0
Pcdf = Pcdf/Pcdf(end); % Normalise to make sure Pcdf ends with 1

% Make sure Pcdf is monotonically increasing. P is nonnegative but not
% necessarily positive, therefore Pcdf may contain sections with zero
% derivative. To use interp1, Pcdf must contain unique points:
[Pcdf,I] = unique(Pcdf);
R = R(I);

% Convert random numbers from a uniform distribution to random numbers
% from a nonuniform probability density function by interpolation of the 
% cdf:
X = interp1(Pcdf,R,rand(1,N));

end
