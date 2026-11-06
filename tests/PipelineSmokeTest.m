classdef (SharedTestFixtures = {ProteusTestEnvironment}) ...
        PipelineSmokeTest < matlab.unittest.TestCase
%PIPELINESMOKETEST End-to-end runs of features without a reference
%baseline: a curved array and calibrated impulse responses, through
%main_RF, main_pressure_field and the delay-and-sum beamformers.
%
% These runs check that the pipeline completes and gives finite, non-zero
% outputs. Requires k-Wave (incomplete without it, failed in strict mode).

    methods (TestClassSetup)
        function requireKWave(testCase)
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            ok = env.meetsRequirements({'kWave'});
            if strcmp(getenv('PROTEUS_TEST_STRICT'),'1')
                testCase.assertTrue(ok, 'Requires k-Wave.');
            else
                testCase.assumeTrue(ok, 'Requires k-Wave.');
            end
        end
    end

    methods (TestMethodSetup)
        function restorePath(testCase)
            % The simulators remove microbubble-simulator/functions from the
            % path when they finish; later tests need it.
            testCase.addTeardown(@path, path);
        end
    end

    methods (Test, TestTags = {'EndToEnd'})
        function curvedArrayRFAndReconstruction(testCase)
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            S = make_tiny_curved_settings(env.PATHS);
            [out, resultDir, settingsFile] = run_rf_simulation(env, S, ...
                'smoke_curved_rf');
            testCase.verifyRFIsValid(out, S);

            [IMG, x, y] = DAS_reconstruction_general(resultDir, settingsFile);
            testCase.verifySize(IMG, [numel(x) numel(y) numel(out.RF)]);
            testCase.verifyEqual(max(IMG,[],[1 2]), zeros(1,1,numel(out.RF)));
        end

        function curvedArrayPressureField(testCase)
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            S = make_tiny_curved_settings(env.PATHS);
            P = env.PATHS;
            settingsFile = fullfile(P.SettingsPath,'smoke_curved_field.mat');
            write_settings(S, P, settingsFile);
            main_pressure_field(settingsFile, 'smoke_curved_field');
            R = load(fullfile(P.ResultsPath,'smoke_curved_field', ...
                'pressure_maps.mat'));
            for f = {'sensor_data_xy','sensor_data_xz'}
                p = [R.(f{1}).p_max(:); R.(f{1}).p_min(:)];
                testCase.verifyTrue(all(isfinite(p)), f{1});
                testCase.verifyGreaterThan(max(abs(p)), 0, f{1});
            end
        end

        function calibratedLinearArrayRF(testCase)
            % Linear array with calibrated impulse responses (those of the
            % C1-6D model file) and the default transducer otherwise.
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            S = make_tiny_settings(env.PATHS, 'current');
            C.Type = 'C1-6D'; C = get_transducer_properties(C);
            for f = {'TransmitImpulseResponse','ReceiveImpulseResponse', ...
                    'SamplingRate','ImpulseResponseType','calibrated'}
                S.Transducer.(f{1}) = C.(f{1});
            end
            S.Transmit = reset_transmit(S.Transducer);
            S = update_derived_settings(S);
            [out, resultDir, settingsFile] = run_rf_simulation(env, S, ...
                'smoke_calibrated_rf');
            testCase.verifyRFIsValid(out, S);

            % Both beamformers accept the data of a linear array:
            % Both beamformers return axial-by-lateral images:
            [IMG0, x0, y0] = DAS_reconstruction(resultDir, settingsFile);
            [IMG1, x1, y1] = DAS_reconstruction_general(resultDir, settingsFile);
            testCase.verifySize(IMG0, [numel(x0) numel(y0) numel(out.RF)]);
            testCase.verifySize(IMG1, [numel(x1) numel(y1) numel(out.RF)]);
            testCase.verifyEqual(x0(1), 0);   % axial from the transducer
            testCase.verifyLessThan(y0(1), 0);   % lateral, centred
            testCase.verifyGreaterThan(y0(end), 0);
        end
    end

    methods (Access = private)
        function verifyRFIsValid(testCase, out, S)
            testCase.verifyNumElements(out.RF, S.Acquisition.NumberOfFrames);
            for k = 1:numel(out.RF)
                RF = out.RF{k}{1};
                testCase.verifySize(RF, [S.Transducer.NumberOfElements, ...
                    size(RF,2)]);
                testCase.verifyTrue(all(isfinite(RF(:))));
                testCase.verifyGreaterThan(max(abs(RF(:))), 0);
            end
        end
    end
end
