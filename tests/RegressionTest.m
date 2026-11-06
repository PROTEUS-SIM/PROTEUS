classdef (SharedTestFixtures = {ProteusTestEnvironment}) ...
        RegressionTest < matlab.unittest.TestCase
%REGRESSIONTEST Golden-master tests against the original PROTEUS outputs.
%
% Every case in tests/helpers/regression_cases.m is run and its outputs are
% compared with tests/baseline/<case>.mat.
%
% Cases whose requirements (k-Wave) are not met are reported as
% incomplete, unless the environment variable PROTEUS_TEST_STRICT is 1 (as
% in CI), in which case they fail.
% Cases without a recorded baseline are always reported as incomplete.

    properties (TestParameter)
        caseName = RegressionTest.caseNames();
    end

    methods (Test)
        function matchesBaseline(testCase, caseName)
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            C = regression_cases();
            c = C(strcmp({C.name}, caseName));

            if strcmp(getenv('PROTEUS_TEST_STRICT'),'1')
                check = @testCase.assertTrue;
            else
                check = @testCase.assumeTrue;
            end

            [ok, missing] = env.meetsRequirements(c.requires);
            check(ok, ['Missing requirement(s): ' strjoin(missing, ', ')]);

            baselineFile = fullfile(env.RepoRoot,'tests','baseline', ...
                [caseName '.mat']);
            testCase.assumeTrue(isfile(baselineFile), ...
                ['No baseline recorded for ' caseName '.']);
            B = load(baselineFile,'expected');

            testCase.addTeardown(@rng, rng);
            rng(0,'twister');
            actual = c.fcn(env);

            verify_matches_baseline(testCase, actual, B.expected, ...
                c.relTol, caseName);
        end
    end

    methods (Static, Access = private)
        function names = caseNames()
            here = fileparts(mfilename('fullpath'));
            oldPath = addpath(fullfile(here,'helpers'));
            restore = onCleanup(@() path(oldPath));
            C = regression_cases();
            names = {C.name};
        end
    end
end
