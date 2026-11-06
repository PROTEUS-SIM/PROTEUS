classdef (SharedTestFixtures = {ProteusTestEnvironment}) ...
        TruncatedNormalTest < matlab.unittest.TestCase
%TRUNCATEDNORMALTEST random_truncated_normal (base MATLAB) must reproduce
%the Statistics and Machine Learning Toolbox draw used by the original
%define_medium, random(truncate(makedist('Normal'),-c,c),sz).
%
% The toolbox draws are stored in tests/baseline/truncated_normal.mat
% (recorded with tests/tools/record_truncated_normal_reference.m), so the
% toolbox is not needed to run this test.

    properties (TestParameter)
        reference = TruncatedNormalTest.referenceDraws();
        cutoff = {1, 2, 2.5, 3};
    end

    methods (Test, TestTags = {'Fast'})
        function matchesToolboxBitForBit(testCase, reference)
            testCase.addTeardown(@rng, rng);
            rng(reference.seed,'twister');
            actual = random_truncated_normal(reference.cutoff, reference.size);
            testCase.verifyEqual(actual, reference.x);
            % Same number of draws from the global stream:
            testCase.verifyEqual(rand, reference.next);
        end

        function infiniteCutoffIsUntruncated(testCase)
            testCase.addTeardown(@rng, rng);
            rng(5,'twister'); expected = randn([4 5 6]);
            rng(5,'twister'); actual = random_truncated_normal(Inf, [4 5 6]);
            testCase.verifyEqual(actual, expected);
        end

        function invalidCutoffErrors(testCase)
            for c = {0, -1, NaN, [1 2]}
                testCase.verifyError(@() random_truncated_normal(c{1}, [2 2]), ...
                    'random_truncated_normal:invalidCutoff');
            end
        end

        function staysWithinCutoff(testCase, cutoff)
            testCase.addTeardown(@rng, rng);
            rng(1,'twister');
            x = random_truncated_normal(cutoff, [100 100 10]);
            testCase.verifyLessThanOrEqual(max(abs(x(:))), cutoff);
            testCase.verifyEqual(mean(x(:)), 0, 'AbsTol', 0.02);
        end
    end

    methods (Static, Access = private)
        function draws = referenceDraws()
            here = fileparts(mfilename('fullpath'));
            B = load(fullfile(here,'baseline','truncated_normal.mat'),'cases');
            draws = struct();
            for k = 1:numel(B.cases)
                c = B.cases(k);
                name = sprintf('seed%d_cutoff%s_%s', c.seed, ...
                    strrep(num2str(c.cutoff),'.','p'), ...
                    strjoin(string(c.size),'x'));
                draws.(name) = c;
            end
        end
    end
end
