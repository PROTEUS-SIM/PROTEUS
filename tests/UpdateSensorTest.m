classdef (SharedTestFixtures = {ProteusTestEnvironment}) ...
        UpdateSensorTest < matlab.unittest.TestCase
%UPDATESENSORTEST update_sensor_fast must reproduce update_sensor.

    properties (TestParameter)
        onGrid   = {false, true};
        maskOnly = {false, true};
    end

    methods (Test, TestTags = {'Fast'})
        function fastMatchesReference(testCase, onGrid, maskOnly)
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            S = make_tiny_settings(env.PATHS);
            S.SimulationParameters.GridSize = S.Medium.SpeedOfSound/ ...
                (S.Transmit.CenterFrequency* ...
                S.SimulationParameters.PointsPerWavelength);
            S.SimulationParameters.SensorOnGrid = onGrid;
            Grid = define_grid(S.SimulationParameters, S.Geometry);

            stream = RandStream('mt19937ar','Seed',11);
            lo = [Grid.x(1) Grid.y(1) Grid.z(1)];
            hi = [Grid.x(end) Grid.y(end) Grid.z(end)];
            points = lo + (0.1 + 0.8*rand(stream,25,3)).*(hi-lo);
            % Include two coincident points and one exactly on a node:
            points(2,:) = points(1,:);
            points(3,:) = [Grid.x(5) Grid.y(5) Grid.z(5)];
            [points, ~, idx] = voxelize_media_points(points, Grid);

            sensor0.mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz);
            [s_ref,  w_ref ] = update_sensor(     sensor0, points, idx, Grid, maskOnly);
            [s_fast, w_fast] = update_sensor_fast(sensor0, points, idx, Grid, maskOnly);

            testCase.verifyEqual(logical(s_fast.mask), logical(s_ref.mask));
            if ~maskOnly
                testCase.verifyEqual(full(w_fast), full(w_ref), ...
                    'AbsTol', 1e-12*max(abs(w_ref),[],'all'));
            end
        end
    end
end
