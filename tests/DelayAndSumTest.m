classdef (SharedTestFixtures = {ProteusTestEnvironment}) ...
        DelayAndSumTest < matlab.unittest.TestCase
%DELAYANDSUMTEST The general beamformer (compute_das_matrix_general) against
%the reference beamformer (compute_das_matrix) and the transmit delays.
%
% Coordinates: x axial (depth), y lateral (PROTEUS convention). The
% reference matrix orders its pixels lateral first, the general one axial
% first (image = reshape(M*RF, Nx, Ny)).

    properties (TestParameter)
        Nelem = {8, 9};             % even and odd number of elements
    end

    properties (Constant)
        c  = 1540;                  % [m/s]
        Fs = 40e6;                  % [Hz]
        Nt = 600;
        pitch = 0.3e-3;             % [m]
    end

    methods (Test, TestTags = {'Fast'})
        function planeWaveMatchesReferenceExactly(testCase, Nelem)
            [t, x, y, y_el, recon, tr] = testCase.linear_case(Nelem);
            M0 = compute_das_matrix(t, y, x, y_el, testCase.c, testCase.Fs, Inf);
            M1 = compute_das_matrix_general(recon, tr, ...
                struct('focus', Inf, 'steer', 0));
            testCase.verifyEqual(M1(lateral_first(x, y),:), M0);
        end

        function divergingWaveMatchesReferenceWithinOneSample(testCase, Nelem)
            % The reference starts the diverging wave at distance F from
            % the virtual source, the general beamformer at the closest
            % element (which coincides for an odd number of elements).
            [t, x, y, y_el, recon, tr] = testCase.linear_case(Nelem);
            F = 10e-3;
            M0 = compute_das_matrix(t, y, x, y_el, testCase.c, testCase.Fs, -F);
            M1 = compute_das_matrix_general(recon, tr, ...
                struct('focus', -F, 'steer', 0));
            M1 = M1(lateral_first(x, y),:);
            % Same (pixel, element) pairs, sample index within one:
            A0 = pixel_element_sample(M0, numel(t));
            A1 = pixel_element_sample(M1, numel(t));
            testCase.verifyEqual(A1(:,1:2), A0(:,1:2));
            testCase.verifyLessThanOrEqual(max(abs(A1(:,3) - A0(:,3))), 1);
            if mod(Nelem,2)
                testCase.verifyEqual(M1, M0);
            end
        end

        function transmitModelMatchesTransmitDelays(testCase)
            % At each element, the transmit path of the beamformer must
            % equal c times the PROTEUS transmit delay.
            M.SpeedOfSound = testCase.c;
            P41 = reference_transducer(reset_transducer());
            C16.Type = 'C1-6D'; C16 = get_transducer_properties(C16);
            cases = { ...
                P41, Inf, 0; P41, Inf, 12; P41, Inf, -15; ...
                P41, -20e-3, 0; P41, -20e-3, -10; P41, 30e-3, 5; ...
                C16, Inf, 0; C16, Inf, 10; C16, -20e-3, 5; C16, 60e-3, -8};
            for k = 1:size(cases,1)
                T = cases{k,1};
                Tx.LateralFocus = cases{k,2}; Tx.Angle = cases{k,3};
                Tx = compute_delays(Tx, T, M);
                El = get_element_geometry(T);
                tr = struct('x_el', El.x', 'y_el', El.y', 'center', El.Center);
                tx = struct('focus', Tx.LateralFocus, ...
                    'steer', deg2rad(Tx.Angle));
                d = das_transmit_distance(El.x, El.y, tr, tx);
                testCase.verifyEqual(d'/testCase.c, Tx.Delays, ...
                    'AbsTol', 1e-14, sprintf('case %d', k));

                % Apodization does not change the time origin:
                tx.apod = double(El.y' > 0);
                testCase.verifyEqual(das_transmit_distance(El.x, El.y, ...
                    tr, tx), d, sprintf('case %d, apodized', k));
            end
        end

        function positiveAngleSteersTowardsPositiveLateral(testCase)
            % Elements at negative lateral positions fire first, so the
            % wavefront travels towards positive lateral positions.
            M.SpeedOfSound = testCase.c;
            T = reference_transducer(reset_transducer());
            Tx.LateralFocus = Inf; Tx.Angle = 10;
            Tx = compute_delays(Tx, T, M);
            testCase.verifyEqual(Tx.Delays(1), 0);
            testCase.verifyTrue(all(diff(Tx.Delays) > 0));
        end

        function pointScattererIsImagedAtItsPosition(testCase)
            % RF data of a point scatterer synthesised from the transmit
            % delays (first arrival over all elements, Huygens), independent
            % of das_transmit_distance. The image peak must be at the
            % scatterer. For focused waves the scatterers lie before the
            % focus, where the first arrival is the focused wavefront.
            M.SpeedOfSound = testCase.c;
            P41 = reference_transducer(reset_transducer());
            C16.Type = 'C1-6D'; C16 = get_transducer_properties(C16);
            cases = { ...
                P41, Inf, 10, [ 4e-3 30e-3]; ...
                P41, 30e-3, -6, [-2e-3 20e-3]; ...
                P41, -20e-3, 0, [ 2e-3 25e-3]; ...
                C16, Inf, 0, [10e-3 45e-3]; ...
                C16, Inf, 8, [-8e-3 40e-3]; ...
                C16, 50e-3, 5, [ 3e-3 35e-3]};
            % Scatterer positions are given as [lateral axial] above.
            Fs = 100e6; c = testCase.c;
            for k = 1:size(cases,1)
                T = cases{k,1};
                Tx.LateralFocus = cases{k,2}; Tx.Angle = cases{k,3};
                Tx = compute_delays(Tx, T, M);
                El = get_element_geometry(T);
                S = fliplr(cases{k,4});   % [axial lateral]
                r = hypot(El.x' - S(1), El.y' - S(2)); % element-scatterer
                t_tx = min(Tx.Delays + r/c);
                t_echo = t_tx + r/c;                    % 1-by-Nelem
                t = (0:round(2.5*max(t_echo)*Fs))/Fs;
                RF = exp(-((t' - t_echo)/30e-9).^2);   % Nt-by-Nelem
                pix = 0.05e-3;
                recon = struct('x', S(1) + (-20:20)*pix, ...
                    'y', S(2) + (-20:20)*pix, 'c', c, 't', t, 'Fs', Fs, ...
                    'alpha_th', pi/3 - (El.Radius < Inf)*pi/6, ...
                    'apodization', 'cosine');
                tr = struct('x_el', El.x', 'y_el', El.y', ...
                    'azimuth', El.theta', 'center', El.Center, ...
                    'radius', El.Radius);
                tx = struct('focus', Tx.LateralFocus, ...
                    'steer', deg2rad(Tx.Angle));
                IMG = reshape(compute_das_matrix_general(recon, tr, tx)*RF(:), ...
                    numel(recon.x), numel(recon.y));
                [~, i] = max(IMG(:));
                [ix, iy] = ind2sub(size(IMG), i);
                testCase.verifyEqual([recon.x(ix) recon.y(iy)], S, ...
                    'AbsTol', 1.01*pix, sprintf('case %d', k));
            end
        end

        function samplesStayWithinTheirElement(testCase)
            % Delays before the first or after the last sample must be
            % discarded, not read from the neighbouring element.
            [~, x, y, y_el, recon, tr] = testCase.linear_case(8);
            recon.t = recon.t(200:260);   % short window: many out of range
            Nt = numel(recon.t);
            M = compute_das_matrix_general(recon, tr, ...
                struct('focus', Inf, 'steer', deg2rad(10)));
            [pix, col] = find(M);
            el = ceil(col/Nt);
            sample = col - (el-1)*Nt;
            % Recompute the element of each entry from its delay:
            [X, Y] = ndgrid(x, y);
            d_in = das_transmit_distance(X(pix), Y(pix), tr, ...
                struct('focus', Inf, 'steer', deg2rad(10)));
            t_del = (hypot(Y(pix) - y_el(el)', X(pix)) + d_in)/testCase.c;
            j = round((t_del - recon.t(1))*testCase.Fs) + 1;
            testCase.verifyEqual(j, sample);
            testCase.verifyTrue(all(sample >= 1 & sample <= Nt));
        end

        function cosineApodizationTapersToThreshold(testCase)
            [~, ~, ~, ~, recon, tr] = testCase.linear_case(1);
            recon.x = 5e-3;
            recon.y = linspace(-10e-3, 10e-3, 201);
            recon.t = (0:4999)/testCase.Fs;
            recon.apodization = 'cosine';
            M = compute_das_matrix_general(recon, tr, ...
                struct('focus', Inf, 'steer', 0));
            alpha = atan2(recon.y', recon.x);
            v = full(max(M,[],2));
            expected = cos(pi/2*alpha/recon.alpha_th);
            expected(abs(alpha) > recon.alpha_th) = 0;
            testCase.verifyEqual(v, expected, 'AbsTol', 1e-12);
        end

        function curvedArrayIgnoresPixelsBehindTheSurface(testCase)
            T.Type = 'C1-6D'; T = get_transducer_properties(T);
            El = get_element_geometry(T);
            recon = struct('x', linspace(-5e-3, 60e-3, 33), ...
                'y', linspace(-40e-3, 40e-3, 41), 'c', testCase.c, ...
                't', (0:3999)/testCase.Fs, 'Fs', testCase.Fs, ...
                'alpha_th', pi/6);
            tr = struct('x_el', El.x', 'y_el', El.y', 'azimuth', El.theta', ...
                'center', El.Center, 'radius', El.Radius);
            M = compute_das_matrix_general(recon, tr, ...
                struct('focus', Inf, 'steer', 0));
            [X, Y] = ndgrid(recon.x, recon.y);
            inside = Y(:).^2 + (X(:) - El.Center).^2 < El.Radius^2;
            used = full(any(M,2));
            testCase.verifyFalse(any(used(inside)));
            testCase.verifyTrue(any(used(~inside)));
        end

        function initializationUsesLateralElementPositions(testCase)
            env = testCase.getSharedTestFixtures('ProteusTestEnvironment');
            S = make_tiny_curved_settings(env.PATHS);
            S.Transmit.Angle = 7;
            S.SimulationParameters.GridSize = 1e-4;
            N = S.Transducer.NumberOfElements;
            [recon, tr, tx] = initialize_das_parameters(S.Medium, ...
                S.SimulationParameters, S.Transducer, S.Transmit, ...
                S.Geometry, N, 100);
            El = get_element_geometry(S.Transducer);
            testCase.verifyEqual(tr.x_el, El.x');
            testCase.verifyEqual(tr.y_el, El.y');
            % Image axes: x axial over the domain depth, y lateral:
            testCase.verifyEqual(recon.x(1), S.Geometry.Domain.Xmin);
            testCase.verifyLessThanOrEqual(recon.x(end), S.Geometry.Domain.Xmax);
            W = S.Geometry.Domain.Ymax - S.Geometry.Domain.Ymin;
            testCase.verifyEqual(recon.y(1), -W/2, 'AbsTol', 1e-15);
            testCase.verifyEqual(tr.azimuth, El.theta');
            testCase.verifyEqual(tx.steer, deg2rad(7));
            testCase.verifyEqual(tx.axis_delay, 0);
            testCase.verifyEqual(recon.alpha_th, pi/6);
            testCase.verifyError(@() initialize_das_parameters(S.Medium, ...
                S.SimulationParameters, S.Transducer, S.Transmit, ...
                S.Geometry, N+1, 100), 'initialize_das_parameters:elements');
        end
    end

    methods (Access = private)
        function [t, x, y, y_el, recon, tr] = linear_case(testCase, Nelem)
            t = ((0:testCase.Nt-1)/testCase.Fs - 1.3e-6)';
            y_el = -testCase.pitch/2*(Nelem-1) + (0:Nelem-1)*testCase.pitch;
            x = 0:1e-4:8e-3;      % axial
            y = -3e-3:1e-4:3e-3;  % lateral
            recon = struct('x', x, 'y', y, 'c', testCase.c, 't', t', ...
                'Fs', testCase.Fs, 'alpha_th', pi/3, 'apodization', 'binary');
            tr = struct('x_el', zeros(1,Nelem), 'y_el', y_el, ...
                'azimuth', zeros(1,Nelem), 'center', -Inf, 'radius', Inf);
        end
    end
end

function A = pixel_element_sample(M, Nt)
% Rows [pixel element sample] of the nonzeros of a DAS matrix, sorted.
[pix, col] = find(M);
el = ceil(col/Nt);
A = sortrows([pix el col-(el-1)*Nt]);
end

function rows = lateral_first(x, y)
% Rows of a general DAS matrix (axial index fastest) in the pixel order of
% compute_das_matrix (lateral index fastest).
G = reshape(1:numel(x)*numel(y), numel(x), numel(y));
rows = reshape(G', [], 1);
end
