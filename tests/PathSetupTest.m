classdef (SharedTestFixtures = {ProteusTestEnvironment}) ...
        PathSetupTest < matlab.unittest.TestCase
%PATHSETUPTEST Configuration of paths and the k-Wave version check.

    properties
        Env
        Shim     % fake k-Wave folder with an adjustable Contents.m
    end

    methods (TestMethodSetup)
        function setupFakeKWave(testCase)
            testCase.Env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            import matlab.unittest.fixtures.TemporaryFolderFixture
            tmp = testCase.applyFixture(TemporaryFolderFixture);
            testCase.Shim = fullfile(tmp.Folder,'k-Wave');
            mkdir(fullfile(testCase.Shim,'binaries'));
            old = getenv('PROTEUS_LOCAL_PATHS');
            testCase.addTeardown(@setenv,'PROTEUS_LOCAL_PATHS',old);
        end
    end

    methods (Test, TestTags = {'Fast'})
        function customPathsAreUsed(testCase)
            testCase.useKWaveVersion('1.4.1');
            P = path_setup();
            testCase.verifyEqual(P.kWavePath, testCase.Shim);
            testCase.verifyEqual(P.BinaryPath, fullfile(testCase.Shim,'binaries'));
            testCase.verifyEqual(P.ResultsPath, testCase.Env.PATHS.ResultsPath);
        end

        function rejectsOldKWave(testCase)
            testCase.useKWaveVersion('1.3');
            testCase.verifyError(@path_setup, 'path_setup:kWaveVersion');
        end

        function acceptsOtherPatchVersion(testCase)
            testCase.useKWaveVersion('1.4.2');
            testCase.verifyWarningFree(@path_setup);
        end

        function missingConfigFileErrors(testCase)
            setenv('PROTEUS_LOCAL_PATHS', fullfile(tempdir,'does_not_exist.m'));
            testCase.verifyError(@path_setup, 'path_setup:missingConfig');
        end

        function nonTextValueErrors(testCase)
            testCase.useKWaveVersion('1.4.1', 'PATHS_LOCAL.ResultsPath = 3;');
            testCase.verifyError(@path_setup, 'path_setup:invalidConfig');
        end

        function unknownFieldErrors(testCase)
            testCase.useKWaveVersion('1.4.1', 'PATHS_LOCAL.NotAPath = ''x'';');
            testCase.verifyError(@path_setup, 'path_setup:unknownField');
        end
    end

    methods (Access = private)
        function useKWaveVersion(testCase, version, extraLine)
            if nargin < 3; extraLine = ''; end
            write(fullfile(testCase.Shim,'Contents.m'), ...
                ['% Version ' version ' 01-Jan-2026']);
            P = testCase.Env.PATHS;
            file = fullfile(fileparts(testCase.Shim),'paths.m');
            write(file, strjoin({ ...
                sprintf('PATHS_LOCAL.kWavePath = ''%s'';', testCase.Shim), ...
                sprintf('PATHS_LOCAL.ResultsPath = ''%s'';', P.ResultsPath), ...
                sprintf('PATHS_LOCAL.DataPath = ''%s'';', P.DataPath), ...
                sprintf('PATHS_LOCAL.SettingsPath = ''%s'';', P.SettingsPath), ...
                sprintf('PATHS_LOCAL.GroundTruthPath = ''%s'';', P.GroundTruthPath), ...
                extraLine}, newline));
            setenv('PROTEUS_LOCAL_PATHS', file);
        end
    end
end

function write(file, text)
fid = fopen(file,'w');
fprintf(fid,'%s\n',text);
fclose(fid);
end
