classdef (SharedTestFixtures = {ProteusTestEnvironment}) ...
        VersionTest < matlab.unittest.TestCase
%VERSIONTEST proteus_version must be a semantic version and match
%CITATION.cff.

    methods (Test, TestTags = {'Fast'})
        function versionIsSemantic(testCase)
            [v, parts] = proteus_version();
            testCase.verifyMatches(v, '^\d+\.\d+\.\d+$');
            testCase.verifyEqual(parts, sscanf(v, '%d.%d.%d')');
            testCase.verifySize(parts, [1 3]);
        end

        function versionMatchesCitation(testCase)
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            cff = fileread(fullfile(env.RepoRoot, 'CITATION.cff'));
            tok = regexp(cff, '(?m)^version:\s*"?([\d.]+)"?\s*$', 'tokens', 'once');
            testCase.assertNotEmpty(tok, 'No version in CITATION.cff.');
            testCase.verifyEqual(proteus_version(), tok{1});
        end
    end
end
