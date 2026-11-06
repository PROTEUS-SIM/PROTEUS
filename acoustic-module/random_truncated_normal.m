function x = random_truncated_normal(cutoff, sz)
%RANDOM_TRUNCATED_NORMAL Standard normal random numbers truncated at
%+/-cutoff.
%
% X = RANDOM_TRUNCATED_NORMAL(CUTOFF, SZ) returns an array of size SZ.
%
% Draws standard normal random numbers truncated at +/-cutoff by inverse
% transform sampling of rand. Reproduces, bit for bit and from the same
% random number stream, random(truncate(makedist('Normal'),-cutoff,cutoff),
% sz) of the Statistics and Machine Learning Toolbox, without requiring it
% (the lower limit is evaluated just below -cutoff, as the toolbox does).

if ~(isscalar(cutoff) && isnumeric(cutoff) && cutoff > 0)
    error('random_truncated_normal:invalidCutoff', ...
        'The cutoff must be a positive scalar.')
end
if isinf(cutoff)
    % No truncation (as the toolbox does for infinite limits):
    x = randn(sz);
    return
end

normcdf_std = @(z) 0.5*erfc(-z./sqrt(2));

lower = -cutoff - eps(-cutoff);
if lower + eps(lower) < -cutoff
    lower = lower + eps(lower);
end
p_lower = normcdf_std(lower);
p_upper = normcdf_std(cutoff);

p = p_lower + rand(sz)*(p_upper - p_lower);
x = -sqrt(2).*erfcinv(2*p);

% Guard against round-off outside the truncation limits:
x = min(max(x, -cutoff), cutoff);
end
