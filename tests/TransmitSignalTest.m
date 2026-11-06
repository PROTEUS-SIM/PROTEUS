classdef (SharedTestFixtures = {ProteusTestEnvironment}) ...
        TransmitSignalTest < matlab.unittest.TestCase
%TRANSMITSIGNALTEST Custom transmit signals (issue #3: a mostly negative
%custom voltage waveform gave a zero amplitude and NaN signals).

    methods (Test, TestTags = {'Fast'})
        function negativeCustomVoltageIsScaledToAmplitude(testCase)
            Transducer = reference_transducer(reset_transducer());
            Transmit = reset_transmit(Transducer);
            Transmit.Type = 'Custom (voltage)';
            Transmit.AmplitudeMode = 'Voltage';
            Transmit.VoltageSignal = -[0 0.5 1 0.5 0 0.2 0];
            Transmit.VoltageAmplitude = 10;      % [V]

            Transmit = get_voltage_signal(Transmit);
            Transmit = get_pressure_signal(Transmit, Transducer);

            V = Transmit.VoltageSignal;
            testCase.verifyTrue(all(isfinite(V)));
            testCase.verifyEqual(max(abs(V)), 10, 'RelTol', 1e-12);
            testCase.verifyEqual(V(3), -10, 'RelTol', 1e-12);   % shape kept
            testCase.verifyTrue(isfinite(Transmit.MechanicalIndex));
            testCase.verifyGreaterThan(Transmit.AcousticPressure, 0);
        end

        function exampleCustomFilesHoldVariables(testCase)
            % The custom-data files are mat files with plain variables (as
            % documented in documentation/TransmitGUI.md, issue #8).
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            folder = fullfile(env.RepoRoot, 'example_custom_data');
            expected = {'custom_voltage_signal.mat','V'; ...
                'custom_pressure_signal.mat','p'; ...
                'custom_delays.mat','delays'; ...
                'custom_apodization.mat','apodization'; ...
                'custom_transmit_impulse_response.mat','IR'; ...
                'custom_receive_impulse_response.mat','IR'};
            for k = 1:size(expected,1)
                w = whos('-file', fullfile(folder, expected{k,1}));
                testCase.verifyEqual({w.name}, expected(k,2), expected{k,1});
                testCase.verifyTrue(strcmp(w.class,'double'), expected{k,1});
            end
        end

        function singleCustomTransmitGivesDoubleSource(testCase)
            % Custom delays saved as single made the source signals single;
            % before R2025a, the product with the sparse source weights then
            % failed ("MTIMES is not supported for one sparse argument and
            % one single argument"). The source must be double.
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            S = make_default_settings(env.PATHS, 'tiny_box', 'current');
            S.Transducer.Type = 'P4-1';
            S.Transducer = get_transducer_properties(S.Transducer);
            S.Transmit = reset_transmit(S.Transducer);
            S.SimulationParameters.PointsPerWavelength = 2;
            S = update_derived_settings(S);
            S.SimulationParameters.GridSize = S.Medium.SpeedOfSound/ ...
                (S.Transmit.CenterFrequency*2);
            Grid = define_grid(S.SimulationParameters, S.Geometry);
            Grid.dt = 1e-8;
            T = S.Transducer;
            T.OnGrid = false;
            T.IntegrationDensity = 1;
            T = get_transducer_integration_points(T, Grid);
            T = get_transducer_integration_delays(T, S.Medium);
            Nel = T.NumberOfElements;

            Tx.PressureSignal = single([0 1 -1 0]);
            Tx.Delays = single(linspace(0, 1e-7, Nel));
            Tx.Apodization = single(ones(1, Nel));
            Tx.SeqPulse = 'full';
            Medium.SpeedOfSound = 1540; Medium.Density = 1000;

            for type = {'dipole','monopole'}
                T.SourceType = type{1};
                [sensor, w] = define_sensor_transducer(T, Grid);
                src = define_source_transducer(T, Tx, Medium, Grid, w', ...
                    find(sensor.mask));
                if isfield(src,'ux'), s = src.ux; else, s = src.p; end
                testCase.verifyClass(s, 'double', type{1});
                testCase.verifyTrue(all(isfinite(s(:))), type{1});
            end
        end
    end
end
