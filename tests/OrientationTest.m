classdef (SharedTestFixtures = {ProteusTestEnvironment}) ...
        OrientationTest < matlab.unittest.TestCase
%ORIENTATIONTEST One coordinate convention: x axial (depth), y lateral,
%z elevation (height).
%
% Every catalogue transducer must lie entirely on the simulation grid built
% for it, with a non-empty sensor mask. A transducer and a grid in
% different orientations (for example z as depth) must raise an error
% instead of producing an empty sensor mask.

    properties (TestParameter)
        type = {'P4-1','C1-6D','L22-14v','9L-D','RC6gV'};
    end

    methods (Test, TestTags = {'Fast'})
        function transducerLiesOnItsGrid(testCase, type)
            [T, Grid] = testCase.transducerOnGrid(type);
            Npoints = numel(T.integration_points)/3;
            [sensor, w] = define_sensor_transducer(T, Grid);
            testCase.verifyGreaterThan(nnz(sensor.mask), 0);
            % One row of weights per integration point, none empty:
            testCase.verifySize(w, [Npoints nnz(sensor.mask)]);
            testCase.verifyTrue(all(any(w,2)));

            % Elements along y (lateral), surface facing +x, height along z:
            P = reshape(T.integration_points, [], 3);
            span = max(P) - min(P);
            if ~strcmp(T.Configuration,'RCA')
                testCase.verifyGreaterThan(span(2), span(3));
                testCase.verifyGreaterThanOrEqual(min(P(:,1)), 0);
            end
        end

        function otherOrientationIsAnError(testCase)
            % The case reported from standalone use: the C1-6D array on a
            % grid with z as depth and y as height.
            [T, Grid] = testCase.transducerOnGrid('C1-6D');
            G = Grid;
            G.y = Grid.z; G.Ny = Grid.Nz; G.dy = Grid.dz;
            G.z = Grid.x; G.Nz = Grid.Nx; G.dz = Grid.dx;
            G.x = Grid.y; G.Nx = Grid.Ny; G.dx = Grid.dy;
            G.full_size = G.full_size([2 3 1]);
            testCase.verifyError(@() define_sensor_transducer(T, G), ...
                'define_sensor_transducer:pointsOutsideGrid');
        end

        function partlyOutsideIsAnError(testCase)
            % A grid one lateral cell too narrow loses the outer points.
            [T, Grid] = testCase.transducerOnGrid('P4-1');
            P = reshape(T.integration_points, [], 3);
            keep = Grid.y < max(P(:,2)) - Grid.dy/2;
            Grid.y = Grid.y(keep); Grid.Ny = numel(Grid.y);
            testCase.verifyError(@() define_sensor_transducer(T, Grid), ...
                'define_sensor_transducer:pointsOutsideGrid');
        end

        function sourceVariantsStayOnTheGrid(testCase)
            % On-grid sensors with denser integration, and dipole sources
            % (points shifted by half a cell), stay on the same grid. Linear
            % and curved arrays (the row-column array takes too long here).
            for type = {'P4-1','C1-6D'}
                [T, Grid] = testCase.transducerOnGrid(type{1}, 3);
                T.OnGrid = true;
                sensor = define_sensor_transducer(T, Grid);
                testCase.verifyGreaterThan(nnz(sensor.mask), 0, type{1});

                [T, Grid] = testCase.transducerOnGrid(type{1});
                T.OnGrid = false;
                T.SourceType = 'dipole';
                T = get_transducer_integration_delays(T, ...
                    struct('SpeedOfSound',1540));
                Tx.PressureSignal = [0 1 -1 0];
                Tx.Delays = zeros(1, T.NumberOfElements);
                Tx.Apodization = ones(1, T.NumberOfElements);
                Tx.SeqPulse = 'full';
                Grid.dt = 1e-8;
                Medium.SpeedOfSound = 1540; Medium.Density = 1000;
                [sensor, w] = define_sensor_transducer(T, Grid);
                src = define_source_transducer(T, Tx, Medium, Grid, w', ...
                    find(sensor.mask));
                testCase.verifyGreaterThan(nnz(src.u_mask), 0, type{1});
            end
        end

        function customTransducerInOtherOrientationWarns(testCase)
            [T, Grid] = testCase.transducerOnGrid('P4-1');
            T.integration_points = T.integration_points(:,:,[2 3 1]);
            T.integration_area = 1e-8;
            T.Configuration = 'Custom';
            testCase.verifyWarning(@() get_transducer_integration_points( ...
                T, Grid), 'get_transducer_integration_points:orientation');
            [T0, Grid] = testCase.transducerOnGrid('P4-1');
            T0.Configuration = 'Custom';
            T0.integration_area = 1e-8;
            testCase.verifyWarningFree(@() get_transducer_integration_points( ...
                T0, Grid));
        end

        function modelFilesHoldNoGridDependentData(testCase)
            % Integration points depend on the grid and its orientation;
            % model files must not provide them (they would be ignored).
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            files = dir(fullfile(env.RepoRoot,'Transducer-models','*.mat'));
            for k = 1:numel(files)
                S = load(fullfile(files(k).folder, files(k).name));
                if isfield(S,'Transducer')
                    names = fieldnames(S.Transducer);
                    testCase.verifyEmpty(names(startsWith(names, ...
                        'integration') | strcmp(names,'Axis')), files(k).name);
                end
            end
        end
    end

    methods (Access = private)
        function [T, Grid] = transducerOnGrid(testCase, type, density)
            % Transducer with its default transmit, on the grid of the
            % (synthetic) geometry, at 2 points per wavelength, with
            % integration point density density (default 1).
            if nargin < 3
                density = 1;
            end
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            S = make_default_settings(env.PATHS, 'tiny_box', 'current');
            S.Transducer.Type = type;
            S.Transducer = get_transducer_properties(S.Transducer);
            if strcmp(S.Transducer.ImpulseResponseType,'Estimate')
                S.Transducer = estimate_impulse_response(S.Transducer);
            end
            S.Transmit = reset_transmit(S.Transducer);
            if strcmp(S.Transducer.Configuration,'Curved')
                % Geometry in front of the array surface:
                El = get_element_geometry(S.Transducer);
                S.Geometry.startDepth = El.Apex + 1e-3;
            end
            S.SimulationParameters.PointsPerWavelength = 2;
            S = update_derived_settings(S);
            S.SimulationParameters.GridSize = S.Medium.SpeedOfSound/ ...
                (S.Transmit.CenterFrequency*2);
            Grid = define_grid(S.SimulationParameters, S.Geometry);
            T = S.Transducer;
            T.OnGrid = false;
            T.IntegrationDensity = density;
            T = get_transducer_integration_points(T, Grid);
        end
    end
end
