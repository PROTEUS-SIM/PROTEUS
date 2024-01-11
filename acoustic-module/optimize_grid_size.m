function N = optimize_grid_size(N, expand_range, maxPrime)
% Search grid sizes which can be factorized into prime factors with a 
% maximum prime factor.
%
% INPUT:
% N:            grid size 
% expand_range: two-element array with minimum and maximum grid size
%               increment.
% maxPrime:     largest allowable prime factor
%
% OUTPUT:
% N:            new grid size

% Create array of full grid sizes to search
M = N + (min(expand_range):max(expand_range));

% Compute largest prime factor for each grid size in M_array:
maxPrimeFactors = zeros(1, length(M));

for index = 1:length(M)
    maxPrimeFactors(index) = max(factor(M(index)));
end

% Get full grid size with smallest prime factors:
[fac, ind_opt] = min(maxPrimeFactors);

N = M(ind_opt);

% If the minimum largest factor is larger than maxPrime, keep increasing
% the grid size until the minimum largest factor is maxPrime or less:
if fac > maxPrime
    N = M(end);
    while max(factor(N))>maxPrime 
        N = N + 1;
    end
end

end