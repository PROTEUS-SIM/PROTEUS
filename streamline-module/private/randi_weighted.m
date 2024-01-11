function R = randi_weighted(P,N,M)
%RANDI_WEIGHTED Pseudorandom integers from a nonuniform distribution.
%	R = randi_weighted(P,N,M) returns an N-by-M matrix containing 
%	pseudorandom integer values drawn from the discrete distribution given
%	by the array P on 1:numel(P).
%
%   Nathan Blanken, University of Twente, 2023

Pcml = cumsum(P);       % Cumulative probability density
Pcml = Pcml/Pcml(end);  % Normalise probability density
R = arrayfun(@(x) find(subplus(Pcml - x),1), rand(N,M));

end