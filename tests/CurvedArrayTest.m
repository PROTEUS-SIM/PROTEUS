classdef (SharedTestFixtures = {ProteusTestEnvironment}) ...
        CurvedArrayTest < matlab.unittest.TestCase
%CURVEDARRAYTEST Geometry, delays, domain, integration points, medium and
%source of curved arrays (Transducer.Configuration = 'Curved').
%
% Convention (get_element_geometry): kerf-free elements of one pitch along
% an arc of radius R, outer edges at x = 0, centre of curvature at
% x = -R*cos(N*p/(2R)).

    properties
        T   % C1-6D transducer (calibrated geometry from Transducer-models)
        El  % its element geometry
    end

    methods (TestMethodSetup)
        function loadTransducer(testCase)
            T.Type = 'C1-6D';
            testCase.T  = get_transducer_properties(T);
            testCase.El = get_element_geometry(testCase.T);
        end
    end

    methods (Test, TestTags = {'Fast'})
        function elementsLieOnTheArc(testCase)
            T = testCase.T; El = testCase.El; R = T.Radius;
            N = T.NumberOfElements;
            testCase.verifyEqual(hypot(El.x - El.Center, El.y), ...
                R*ones(N,1), 'AbsTol', 1e-15);
            % Arc length between neighbouring centres is one pitch:
            testCase.verifyEqual(diff(El.theta)*R, ...
                T.Pitch*ones(N-1,1), 'AbsTol', 1e-15);
            % Symmetric about the axis, element 1 on the negative side:
            testCase.verifyEqual(El.y, -flipud(El.y), 'AbsTol', 1e-15);
            testCase.verifyLessThan(El.y(1), 0);
            % Outer edges at x = 0 and apex in front:
            edge = El.Center + R*cos(El.theta(end) + T.Pitch/(2*R));
            testCase.verifyEqual(edge, 0, 'AbsTol', 1e-15);
            testCase.verifyEqual(El.Apex, R*(1 - cos(El.ThetaMax)), ...
                'AbsTol', 1e-15);
        end

        function invalidRadiusErrors(testCase)
            T = testCase.T;
            for R = {0, -1, Inf, T.NumberOfElements*T.Pitch/pi}
                T.Radius = R{1};
                testCase.verifyError(@() get_element_geometry(T), ...
                    'get_element_geometry:invalidRadius');
            end
        end

        function linearGeometryMatchesReference(testCase)
            T = reference_transducer(reset_transducer());
            El = get_element_geometry(T);
            N = T.NumberOfElements;
            testCase.verifyEqual(El.y', (-(N-1)/2:(N-1)/2)*T.Pitch);
            testCase.verifyEqual(El.x, zeros(N,1));
        end

        function infiniteFocusDivergesFromCentreOfCurvature(testCase)
            [T, El, M, Tx] = testCase.setup_transmit();
            Tx.LateralFocus = Inf; Tx.Angle = 0;
            Tx = compute_delays(Tx, T, M);
            testCase.verifyEqual(Tx.Delays, zeros(1,T.NumberOfElements), ...
                'AbsTol', 1e-15);

            % Steered: virtual source rotated about the origin.
            Tx.Angle = 10;
            Tx = compute_delays(Tx, T, M);
            vs = El.Center*[cosd(10) sind(10)];
            d  = hypot(El.x - vs(1), El.y - vs(2))'/M.SpeedOfSound;
            testCase.verifyEqual(Tx.Delays, d - min(d), 'AbsTol', 1e-15);
        end

        function focusedWaveArrivesAtOnce(testCase)
            [T, El, M, Tx] = testCase.setup_transmit();
            for angle = [0 8]
                Tx.LateralFocus = 40e-3; Tx.Angle = angle;
                Tx = compute_delays(Tx, T, M);
                F = 40e-3*[cosd(angle) sind(angle)];
                arrival = Tx.Delays + ...
                    hypot(El.x - F(1), El.y - F(2))'/M.SpeedOfSound;
                testCase.verifyEqual(arrival, arrival(1)*ones(size(arrival)), ...
                    'AbsTol', 1e-15);
                testCase.verifyEqual(min(Tx.Delays), 0);
            end
        end

        function integrationPointsCoverTheArc(testCase)
            T = testCase.T; El = testCase.El;
            Grid.dx = 1e-4; Grid.dy = 1e-4; Grid.dz = 1e-4;
            T.IntegrationDensity = 1.5;
            T = get_transducer_integration_points(T, Grid);
            P = T.integration_points;
            [N, Nint, ~] = size(P);
            testCase.verifyEqual(N, T.NumberOfElements);

            % On the arc:
            r = hypot(P(:,:,1) - El.Center, P(:,:,2));
            testCase.verifyEqual(r, T.Radius*ones(N,Nint), 'AbsTol', 1e-15);

            % Each element spans one pitch around its centre angle:
            phi = atan2(P(:,:,2), P(:,:,1) - El.Center);
            testCase.verifyEqual(mean(phi,2), El.theta, 'AbsTol', 1e-12);
            halfSpan = T.Pitch/(2*T.Radius);
            testCase.verifyLessThan(max(abs(phi - El.theta),[],2), halfSpan);

            % Same quadrature weight for all points; the total weight is
            % the array area (arc length times the discretised height):
            Nz = numel(unique(round(P(1,:,3)/1e-9)));
            dz = Grid.dz/T.IntegrationDensity;
            area = N*Nint*T.integration_weights*Grid.dy*Grid.dz;
            testCase.verifyEqual(area, N*T.Pitch*Nz*dz, 'RelTol', 1e-12);
        end

        function domainContainsCurvedSurface(testCase)
            S = make_tiny_curved_settings(testCase.env().PATHS);
            D = S.Geometry.Domain;
            N = S.Transducer.NumberOfElements;
            testCase.verifySize(D.TransducerSurface, [4*N 3]);
            El = get_element_geometry(S.Transducer);
            testCase.verifyGreaterThan(D.Xmax, El.Apex);
            % Outer surface corners at x = 0, element 1 on the left:
            testCase.verifyEqual(D.TransducerSurface([2 4*N-3],1), [0; 0], ...
                'AbsTol', 1e-15);
            testCase.verifyLessThan(D.TransducerSurface(2,2), ...
                D.TransducerSurface(4*N-3,2));
            % A diverging wave widens the beam projection:
            W = 2*El.Radius*sin(El.ThetaMax);
            testCase.verifyGreaterThan(max(D.TransducerProjection(:,2)) - ...
                min(D.TransducerProjection(:,2)), W);
        end

        function couplingRegionHasNoScatterers(testCase)
            S = make_tiny_curved_settings(testCase.env().PATHS);
            S.Geometry.GeometriesPath = testCase.env().PATHS.GeometriesPath;
            S.SimulationParameters.GridSize = S.Medium.SpeedOfSound/ ...
                (S.Transmit.CenterFrequency*4);
            Grid = define_grid(S.SimulationParameters, S.Geometry);
            El = get_element_geometry(S.Transducer);
            inside = (Grid.x(:) - El.Center).^2 + ...
                reshape(Grid.y,1,[]).^2 <= El.Radius^2;
            testCase.assumeTrue(any(inside(:)) && any(~inside(:)));

            testCase.addTeardown(@rng, rng);
            rng(1,'twister'); m3 = define_medium(Grid, S.Medium, S.Geometry);
            rng(1,'twister'); m4 = define_medium(Grid, S.Medium, S.Geometry, ...
                S.Transducer);
            c3 = m3.sound_speed; c4 = m4.sound_speed;
            inside = repmat(inside, [1 1 Grid.Nz]);
            testCase.verifyEqual(c4(inside), ...
                S.Medium.SpeedOfSound*ones(nnz(inside),1));
            testCase.verifyEqual(c4(~inside), c3(~inside));

            % A linear array leaves the medium unchanged:
            rng(1,'twister'); m5 = define_medium(Grid, S.Medium, S.Geometry, ...
                reference_transducer(reset_transducer()));
            testCase.verifyEqual(m5.sound_speed, c3);
        end

        function velocitySourceIsNormalToTheSurface(testCase)
            S = make_tiny_curved_settings(testCase.env().PATHS);
            S.SimulationParameters.GridSize = S.Medium.SpeedOfSound/ ...
                (S.Transmit.CenterFrequency*4);
            Grid = define_grid(S.SimulationParameters, S.Geometry);
            T = S.Transducer; T.OnGrid = false; T.IntegrationDensity = 1;
            T = get_transducer_integration_points(T, Grid);
            T = get_transducer_integration_delays(T, S.Medium);
            Tx = S.Transmit; Tx.SeqPulse = 'full';
            Tx.PressureSignal = [0 1 0.5 -0.5 0];
            Tx.Apodization = ones(1,T.NumberOfElements);
            Tx = compute_delays(Tx, T, S.Medium);
            % With one source point per integration point (identity
            % weights), uy/ux at each point is tan(phi):
            P = reshape(T.integration_points, [], 3);
            Np = size(P,1);
            testCase.assumeLessThanOrEqual(Np, Grid.Nx*Grid.Ny*Grid.Nz);
            src = define_source_transducer(T, Tx, S.Medium, Grid, ...
                speye(Np), (1:Np)');
            El = get_element_geometry(T);
            phi = atan2(P(:,2), P(:,1) - El.Center);
            [~, n] = max(abs(src.ux(1,:)));
            testCase.verifyEqual(src.uy(:,n)./src.ux(:,n), tan(phi), ...
                'RelTol', 1e-10);
            % Unit normal: |u| equals the velocity of the same points
            % without the curvature correction (x direction only):
            Tflat = T; Tflat.Configuration = 'Linear';
            flat = define_source_transducer(Tflat, Tx, S.Medium, Grid, ...
                speye(Np), (1:Np)');
            testCase.verifyEqual(hypot(src.ux, src.uy), abs(flat.ux), ...
                'AbsTol', 1e-12*max(abs(flat.ux),[],'all'));

            % Explicit dipole sources (staggered-grid compensation) use a
            % common mask for both components:
            [sensor, w] = define_sensor_transducer(T, Grid);
            T.SourceType = 'dipole';
            src = define_source_transducer(T, Tx, S.Medium, Grid, w', ...
                find(sensor.mask));
            testCase.verifyEqual(size(src.ux), size(src.uy));
            testCase.verifyEqual(size(src.ux,1), nnz(src.u_mask));
        end
    end

    methods (Access = private)
        function [T, El, M, Tx] = setup_transmit(testCase)
            T = testCase.T; El = testCase.El;
            M.SpeedOfSound = 1540;
            Tx = struct();
        end

        function env = env(testCase)
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
        end
    end
end
