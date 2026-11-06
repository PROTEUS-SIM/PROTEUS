function cases = regression_cases()
%REGRESSION_CASES Catalogue of golden-master cases for PROTEUS.
%
% Returns a struct array with fields:
%   name      unique case name (also the baseline file name)
%   fcn       handle @(env) -> struct of outputs, env is a
%             ProteusTestEnvironment instance
%   requires  cell array of requirements: 'kWave', 'Statistics'
%   relTol    tolerance relative to the largest absolute value of each
%             numeric output
%
% The outputs of every case were recorded on the original code base (see
% tests/baseline/README.md) and later versions must reproduce them.

cases = struct('name',{},'fcn',{},'requires',{},'relTol',{});

% Tolerances: 1e-10 for closed-form computations. Cases that include the
% Butterworth (IIR) impulse response estimate use 1e-6: across platforms
% (macOS arm64 vs Linux x86-64, same release) it differs by ~2e-8. The
% microbubble ODE solution (adaptive step size) differs by ~6e-5, hence
% 1e-3 for bubble_mass_source.

add('default_settings',      @case_default_settings,      {}, 1e-6);
add('transducer_catalogue',  @case_transducer_catalogue,  {}, 1e-6);
add('transmit_signals',      @case_transmit_signals,      {}, 1e-6);
add('transmit_delays',       @case_transmit_delays,       {}, 1e-10);
add('medium_and_bubbles',    @case_medium_and_bubbles,    {}, 1e-10);
add('simulation_domain',     @case_simulation_domain,     {}, 1e-10);
add('grid_and_transducer',   @case_grid_and_transducer,   {}, 1e-6);
add('microbubble_sensor',    @case_microbubble_sensor,    {}, 1e-10);
add('bubble_mass_source',    @case_bubble_mass_source,    {'kWave'}, 1e-3);
add('homogeneous_propagation', @case_homogeneous_propagation, {'kWave'}, 1e-5);
add('das_matrix',            @case_das_matrix,            {}, 1e-10);
add('mesh_voxelisation',     @case_mesh_voxelisation,     {}, 0);

add('rf_hybrid_standard',    @case_rf_hybrid_standard, ...
    {'kWave'}, 1e-4);
add('rf_full_pulse_inversion', @case_rf_full_pulse_inversion, ...
    {'kWave'}, 1e-4);
add('pressure_field',        @case_pressure_field, ...
    {'kWave'}, 1e-4);

    function add(name, fcn, requires, relTol)
        cases(end+1) = struct('name',name,'fcn',fcn, ...
            'requires',{requires},'relTol',relTol);
    end
end

%==========================================================================
% CASES WITHOUT k-WAVE
%==========================================================================
function out = case_default_settings(env)
P = env.PATHS;
P.GeometriesPath = fullfile(env.RepoRoot,'geometry_data');
out = make_default_settings(P,'renal_tree');
end

function out = case_transducer_catalogue(~)
types = {'P4-1','L22-14v','9L-D','RC6gV'};
for k = 1:numel(types)
    T.Type = types{k};
    T = get_transducer_properties(T);
    T.ImpulseResponseType = 'Estimate';
    T.SamplingRate = 250e6;
    T = estimate_impulse_response(T);
    T = reference_transducer(T);
    out.(matlab.lang.makeValidName(types{k})) = T;
    clear T
end
end

function out = case_transmit_signals(~)
Transducer = reference_transducer(reset_transducer());
variants = { ...
    'three_level',   'Three-level',     'Rectangular', 2; ...
    'cos_rect',      'Cosine envelope', 'Rectangular', 3; ...
    'cos_hann',      'Cosine envelope', 'Hann',        4};
for k = 1:size(variants,1)
    Transmit = reset_transmit(Transducer);
    Transmit.Type           = variants{k,2};
    Transmit.Envelope       = variants{k,3};
    Transmit.NumberOfCycles = variants{k,4};
    Transmit = get_voltage_signal(Transmit);
    Transmit = get_pressure_signal(Transmit,Transducer);
    out.(variants{k,1}) = Transmit;
end
end

function out = case_transmit_delays(~)
Medium     = reset_medium();
Transducer = reference_transducer(reset_transducer());
Transducer.Configuration = 'Linear';
Transmit   = reset_transmit(Transducer);
foci   = [Inf  Inf  -20e-3  -20e-3  30e-3];
angles = [0    12   0       -15     5];
for k = 1:numel(foci)
    Transmit.LateralFocus = foci(k);
    Transmit.Angle        = angles(k);
    T = compute_delays(Transmit,Transducer,Medium);
    out.delays{k} = T.Delays;
end
Transducer.Configuration = 'RCA';
Transducer.NumberOfElements = 2*Transducer.NumberOfElements;
Transmit.LateralFocus = -20e-3; Transmit.Angle = 10;
T = compute_delays(Transmit,Transducer,Medium);
out.delays_rca = T.Delays;
end

function out = case_medium_and_bubbles(~)
Medium      = reset_medium();
Microbubble = reset_microbubble();
out.medium_default = compute_sound_speed_extrema(assign_medium_properties(Medium));
[out.gauss_R, out.gauss_P] = compute_gaussian_distribution(Microbubble);
[out.poly_R,  out.poly_P]  = compute_polydisperse_distribution();
gases = {'Sulfur hexafluoride','Perfluoropropane','Perfluorobutane'};
for k = 1:numel(gases)
    G.Type = gases{k};
    out.gas{k} = get_gas_properties(G);
end
[out.A_m, out.sig] = compute_surface_tension(Microbubble,Medium);
end

function out = case_simulation_domain(env)
P = env.PATHS;
P.GeometriesPath = fullfile(env.RepoRoot,'geometry_data');
S = make_default_settings(P,'renal_tree');
variants = {Inf 0; Inf 10; -20e-3 0};
for k = 1:size(variants,1)
    S.Transmit.LateralFocus = variants{k,1};
    S.Transmit.Angle        = variants{k,2};
    S2 = update_derived_settings(S);
    out.domain{k} = S2.Geometry.Domain;
    out.center{k} = S2.Geometry.Center;
end
end

function out = case_grid_and_transducer(env)
S = tiny_settings_with_gridsize(env);
Grid = define_grid(S.SimulationParameters, S.Geometry);
T = S.Transducer;
T.OnGrid = false;
T.IntegrationDensity = 1;
T = get_transducer_integration_points(T, Grid);
T = get_transducer_integration_delays(T, S.Medium);
[sensor, sensor_weights] = define_sensor_transducer(T, Grid);
out.Grid = Grid;
out.Transducer         = T; % incl. integration points, weights, delays
out.sensor_mask_idx    = find(sensor.mask);
out.sensor_weights     = full(sensor_weights);
end

function out = case_microbubble_sensor(env)
S = tiny_settings_with_gridsize(env);
Grid = define_grid(S.SimulationParameters, S.Geometry);
stream = RandStream('mt19937ar','Seed',7);
lo = [Grid.x(1) Grid.y(1) Grid.z(1)];
hi = [Grid.x(end) Grid.y(end) Grid.z(end)];
points = lo + (0.2 + 0.6*rand(stream,6,3)).*(hi-lo);
MB.points = points;
MB.radii  = 2e-6*ones(6,1);
MB.velocities = zeros(6,3);
[sensor, sensor_weights, MB, max_dist] = define_sensor_MB(Grid, MB);
out.mask_idx       = find(sensor.mask);
out.sensor_weights = full(sensor_weights);
out.MB             = MB;
out.max_dist       = max_dist;
end

function out = case_bubble_mass_source(env)
S = tiny_settings_with_gridsize(env);
Microbubble = S.Microbubble;
Microbubble.BatchSize = 15;
Microbubble.UseParfor = 'off';
dt = 1/S.SimulationParameters.SamplingRate;
kgrid.dt    = dt;
kgrid.k_max = pi/S.SimulationParameters.GridSize;
% Sensed pressure: the transmit pulse, resampled to the grid rate and
% scaled differently for each bubble.
p  = S.Transmit.PressureSignal;
t0 = (0:numel(p)-1)/S.Transmit.SamplingRate;
t  = 0:dt:(t0(end) + 4e-6);
p  = interp1(t0, p, t, 'linear', 0);
sensed_p = [1; 0.5; 2] * p;
radii    = [1.5e-6; 2e-6; 2.5e-6];
out.mass_source = compute_bubble_mass_source( ...
    sensed_p, radii, kgrid, S.Medium, Microbubble, S.Transmit);
end

function out = case_homogeneous_propagation(~)
% Microbubble-to-sensor propagation in the homogeneous medium
% approximation (used by hybrid_simulator), with and without gridding of
% the distances.
stream = RandStream('mt19937ar','Seed',5);
Nsrc = 4; Nsens = 30; Nt = 300;
kgrid.dt = 1/40e6;
kgrid.Nt = Nt;
medium.density     = 1000 + 10*rand(stream,4,4,4);
medium.sound_speed = 1540 + 5*rand(stream,4,4,4);
medium.alpha_coeff = 0.75*ones(4,4,4);
medium.alpha_power = 1.5*ones(4,4,4);
source.points = 1e-3*rand(stream,Nsrc,3);
t = (0:Nt-1)*kgrid.dt;
source.mass_source = single(sin(2*pi*3e6*t).*exp(-((t-1e-6)/4e-7).^2) ...
    .*(1:Nsrc)');
sensor.points = 1e-3*(rand(stream,Nsens,3) + [5 0 0]);
run_param.DATA_CAST = 'single';
run_param.gridded = false;
out.direct  = run_simulation_homogeneous(run_param, kgrid, medium, source, sensor);
run_param.gridded = true;
out.gridded = run_simulation_homogeneous(run_param, kgrid, medium, source, sensor);
end

function out = case_das_matrix(~)
c  = 1540; Fs = 20e6;
t  = (0:399)'/Fs;
y_el = (-7.5:7.5)*0.3e-3;          % lateral element positions
y  = linspace(-2e-3, 2e-3, 9);     % lateral
x  = linspace(2e-3, 8e-3, 13);     % axial
M_plane = compute_das_matrix(t, y, x, y_el, c, Fs, Inf);
M_focus = compute_das_matrix(t, y, x, y_el, c, Fs, -10e-3);
stream = RandStream('mt19937ar','Seed',3);
RF = randn(stream, numel(t)*numel(y_el), 1);
out.size_plane = size(M_plane);
out.nnz_plane  = nnz(M_plane);
out.img_plane  = full(M_plane*RF);
out.img_focus  = full(M_focus*RF);
end

function out = case_mesh_voxelisation(env)
stl = fullfile(env.RepoRoot,'mesh-voxelisation','Mesh_voxelisation', ...
    'sample.stl');
out.grid = VOXELISE(24, 20, 16, stl, 'xyz');
end

%==========================================================================
% END-TO-END CASES (k-WAVE)
%==========================================================================
function out = case_rf_hybrid_standard(env)
S = make_tiny_settings(env.PATHS);
out = run_rf_simulation(env, S, 'rf_hybrid_standard');
end

function out = case_rf_full_pulse_inversion(env)
S = make_tiny_settings(env.PATHS);
S.SimulationParameters.HybridSimulation = false;
S.Acquisition.PulsingScheme  = 'Pulse inversion';
S.Acquisition.NumberOfPulses = 2;
S.Acquisition.NumberOfFrames = 1;
out = run_rf_simulation(env, S, 'rf_full_pulse_inversion');
end

function out = case_pressure_field(env)
S = make_tiny_settings(env.PATHS);
P = env.PATHS;
settingsFile = fullfile(P.SettingsPath,'pressure_field.mat');
write_settings(S, P, settingsFile);
rng(0,'twister');
main_pressure_field(settingsFile, 'pressure_field');
R = load(fullfile(P.ResultsPath,'pressure_field','pressure_maps.mat'));
out.lateral   = R.sensor_data_xy;
out.elevation = R.sensor_data_xz;
end

%==========================================================================
% HELPERS
%==========================================================================
function S = tiny_settings_with_gridsize(env)
S = make_tiny_settings(env.PATHS);
c    = S.Medium.SpeedOfSound;
f0   = S.Transmit.CenterFrequency;
ppwl = S.SimulationParameters.PointsPerWavelength;
S.SimulationParameters.GridSize = c/(f0*ppwl); % as in write_to_file
end
