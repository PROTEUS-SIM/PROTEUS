classdef (SharedTestFixtures = {ProteusTestEnvironment}) ...
        HomogeneousPropagationTest < matlab.unittest.TestCase
%HOMOGENEOUSPROPAGATIONTEST Batching must not change the results.

    properties (TestParameter)
        % With Nt = 200, 13 sensors and 4 sources, (Nchunk, Nbatch) =
        % (1,1), (3,1) with a partial last chunk, (13,3) with a partial
        % last batch, and (13,4). Sources are only batched once all
        % sensors fit in one chunk.
        maxElements = struct('tiny', 1000, 'chunks', 5000, ...
            'batches', 62400, 'default', 2^26);
    end

    methods (TestClassSetup)
        function requireKWave(testCase)
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            testCase.assumeTrue(env.meetsRequirements({'kWave'}), ...
                'Requires k-Wave (powerLawKramersKronig).');
        end
    end

    methods (Test, TestTags = {'Fast'})
        function chunkingMatchesSingleSourceLoop(testCase, maxElements)
            [run_param, kgrid, medium, source, sensor] = make_problem();
            run_param.gridded = false;
            run_param.MaxArrayElements = maxElements;
            actual = run_simulation_homogeneous( ...
                run_param, kgrid, medium, source, sensor);

            % Reference: one source at a time, all sensors at once.
            avg.c = mean(medium.sound_speed,'all');
            avg.a = mean(medium.alpha_coeff,'all');
            avg.b = mean(medium.alpha_power,'all');
            expected = zeros(size(sensor.points,1), kgrid.Nt, 'single');
            for m = 1:size(source.points,1)
                d = single(vecnorm(sensor.points - source.points(m,:),2,2));
                expected = expected + calc_scatter_attenuated( ...
                    source.mass_source(m,:), avg, kgrid, d);
            end

            testCase.verifyEqual(actual.p, expected, ...
                'AbsTol', 1e-5*max(abs(expected),[],'all'));
        end

        function coincidentSourceAndSensorIsSilent(testCase)
            [run_param, kgrid, medium, source, sensor] = make_problem();
            sensor.points(3,:) = source.points(2,:);
            source.mass_source([1 3 4],:) = 0;
            for gridded = [false true]
                run_param.gridded = gridded;
                run_param.MaxArrayElements = 1000; % several chunks
                out = run_simulation_homogeneous( ...
                    run_param, kgrid, medium, source, sensor);
                testCase.verifyEqual(out.p(3,:), zeros(1,kgrid.Nt,'single'));
                testCase.verifyGreaterThan(max(abs(out.p(1,:))), 0);
            end
        end
    end
end

function [run_param, kgrid, medium, source, sensor] = make_problem()
stream = RandStream('mt19937ar','Seed',21);
Nsrc = 4; Nsens = 13; Nt = 200;
kgrid.dt = 1/40e6;
kgrid.Nt = Nt;
medium.density     = 1000*ones(2,2,2);
medium.sound_speed = 1540 + 5*rand(stream,2,2,2);
medium.alpha_coeff = 0.75*ones(2,2,2);
medium.alpha_power = 1.5*ones(2,2,2);
source.points = 1e-3*rand(stream,Nsrc,3);
t = (0:Nt-1)*kgrid.dt;
source.mass_source = single(sin(2*pi*3e6*t).*exp(-((t-1e-6)/4e-7).^2) ...
    .*(1:Nsrc)');
sensor.points = 1e-3*(rand(stream,Nsens,3) + [2 0 0]);
run_param.DATA_CAST = 'single';
end
