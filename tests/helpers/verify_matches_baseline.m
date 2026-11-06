function verify_matches_baseline(testCase, actual, expected, relTol, location)
%VERIFY_MATCHES_BASELINE Recursively compare outputs with a baseline.
%
% Numeric arrays are compared with an absolute tolerance of relTol times
% the largest absolute value of the expected array, so that near-zero
% samples of a signal are judged on the scale of the whole signal. All
% other values (sizes, classes, strings, logicals) must match exactly.

if nargin < 5
    location = 'output';
end

if isstruct(expected)
    testCase.verifyTrue(isstruct(actual), [location ' is not a struct']);
    if ~isstruct(actual); return; end
    testCase.verifyEqual(sort(fieldnames(actual)), ...
        sort(fieldnames(expected)), [location ': field names differ']);
    testCase.verifyEqual(size(actual), size(expected), ...
        [location ': struct array size differs']);
    if ~isequal(size(actual), size(expected)); return; end
    fields = intersect(fieldnames(actual), fieldnames(expected));
    for n = 1:numel(expected)
        for f = 1:numel(fields)
            sub = sprintf('%s(%d).%s', location, n, fields{f});
            verify_matches_baseline(testCase, actual(n).(fields{f}), ...
                expected(n).(fields{f}), relTol, sub);
        end
    end

elseif iscell(expected)
    testCase.verifyClass(actual, 'cell', location);
    testCase.verifyEqual(size(actual), size(expected), ...
        [location ': cell size differs']);
    if ~iscell(actual) || ~isequal(size(actual), size(expected)); return; end
    for n = 1:numel(expected)
        verify_matches_baseline(testCase, actual{n}, expected{n}, ...
            relTol, sprintf('%s{%d}', location, n));
    end

elseif isnumeric(expected) && ~isempty(expected)
    testCase.verifyEqual(size(actual), size(expected), ...
        [location ': size differs']);
    if ~isequal(size(actual), size(expected)); return; end
    testCase.verifyEqual(class(actual), class(expected), ...
        [location ': class differs']);
    testCase.verifyEqual(issparse(actual), issparse(expected), ...
        [location ': sparsity differs']);
    a = double(full(gather_if_gpu(actual)));
    e = double(full(expected));
    finite = isfinite(e);
    testCase.verifyEqual(isfinite(a), finite, ...
        [location ': non-finite entries differ']);
    testCase.verifyEqual(a(~finite), e(~finite), ...
        [location ': non-finite values differ']);
    scale = max(abs(e(finite)), [], 'all');
    if isempty(scale); scale = 0; end
    relErr = max(abs(a(finite) - e(finite)), [], 'all')/max(scale, realmin);
    testCase.verifyEqual(a(finite), e(finite), ...
        'AbsTol', relTol*scale + eps(scale), ...
        sprintf('%s: max error %.3g relative to max |value| (tolerance %.3g)', ...
        location, relErr, relTol));

else
    testCase.verifyEqual(actual, expected, location);
end
end

function x = gather_if_gpu(x)
if isa(x,'gpuArray')
    x = gather(x);
end
end
