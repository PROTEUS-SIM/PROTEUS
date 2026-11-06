classdef ProteusTestEnvironment < matlab.unittest.fixtures.Fixture
%PROTEUSTESTENVIRONMENT Shared fixture for the PROTEUS test suite.
%
% Sets up an isolated environment in which PROTEUS runs headless:
%   - adds all PROTEUS modules, k-Wave and the test helpers to the path;
%   - creates temporary folders for results, settings, ground truth and a
%     tiny synthetic flow geometry, and points path_setup() to them;
%   - replaces the C++ k-Wave solver (kspaceFirstOrder3DC) by the MATLAB
%     solver, so that no compiled binaries (or GPU) are needed.
%
% The solver shim lives in a temporary folder that path_setup() reports as
% the k-Wave folder. sim_setup() calls addpath(PATHS.kWavePath), which
% therefore moves the shim (not the real k-Wave) to the top of the path.
%
% k-Wave is looked up in the environment variable PROTEUS_KWAVE_PATH, then
% in <repo>/external/k-wave/k-Wave.
%
% path_setup() is redirected through the environment variable
% PROTEUS_LOCAL_PATHS. For code versions predating that mechanism (used to
% record baselines on the reference commit), PATHS.mat is temporarily
% replaced instead and restored on teardown.

    properties (SetAccess = private)
        RepoRoot        % Root of the PROTEUS repository
        KWavePath       % Folder containing kWaveGrid.m ('' if absent)
        TempRoot        % Temporary folder holding all test data
        PATHS           % Paths struct as returned by path_setup()
        HasStatistics   % Statistics and Machine Learning Toolbox usable
    end

    methods
        function setup(fixture)
            here = fileparts(mfilename('fullpath')); % <repo>/tests
            fixture.RepoRoot = fileparts(here);
            root = fixture.RepoRoot;
            oldPath = path;

            fixture.KWavePath = getenv('PROTEUS_KWAVE_PATH');
            if isempty(fixture.KWavePath)
                fixture.KWavePath = fullfile(root,'external','k-wave','k-Wave');
            end
            if ~isfile(fullfile(fixture.KWavePath,'kWaveGrid.m'))
                fixture.KWavePath = '';
            end

            % Module folders (same set the GUI and main_RF put on the path):
            addpath(root, ...
                fullfile(root,'GUIfunctions'), ...
                fullfile(root,'acoustic-module'), ...
                fullfile(root,'streamline-module'), ...
                fullfile(root,'microbubble-simulator'), ...
                fullfile(root,'microbubble-simulator','functions'), ...
                fullfile(root,'mesh-voxelisation','Mesh_voxelisation'), ...
                fullfile(root,'delay-and-sum'));
            if ~isempty(fixture.KWavePath)
                addpath(fixture.KWavePath)
            end
            addpath(fullfile(here,'helpers'))

            % Temporary data folders:
            fixture.TempRoot = tempname;
            mkdir(fixture.TempRoot);
            fixture.addTeardown(@rmdir, fixture.TempRoot, 's');
            % Teardowns run in reverse order: restore the path before the
            % temporary folders on it are deleted.
            fixture.addTeardown(@path, oldPath);
            sub = @(name) fullfile(fixture.TempRoot,name);
            folders = {'RESULTS','simulation-settings', ...
                'ground_truth_frames','geometry_data','kwave-shim', ...
                fullfile('kwave-shim','binaries')};
            for k = 1:numel(folders)
                mkdir(sub(folders{k}));
            end
            write_tiny_geometry(sub('geometry_data'));

            % Folder reported as k-Wave: solver shim + version file.
            shim = sub('kwave-shim');
            copyfile(fullfile(here,'shims','*.m'), shim);
            if isempty(fixture.KWavePath)
                write_text(fullfile(shim,'Contents.m'), ...
                    '% Version 1.4.1 (test stub, k-Wave not installed)');
            else
                copyfile(fullfile(fixture.KWavePath,'Contents.m'), shim);
            end
            addpath(shim) % on top of the real k-Wave

            custom = struct( ...
                'kWavePath',       shim, ...
                'BinaryPath',      fullfile(shim,'binaries'), ...
                'GeometriesPath',  sub('geometry_data'), ...
                'GroundTruthPath', sub('ground_truth_frames'), ...
                'DataPath',        sub('RESULTS'), ...
                'ResultsPath',     sub('RESULTS'), ...
                'SettingsPath',    sub('simulation-settings'));

            if supports_local_paths(root)
                redirect_with_environment(fixture, custom);
            else
                redirect_with_paths_mat(fixture, custom);
            end

            fixture.PATHS = path_setup();

            fixture.HasStatistics = ~isempty(ver('stats')) && ...
                license('test','Statistics_Toolbox');

            fixture.SetupDescription = ...
                'Set up PROTEUS test paths, solver shim and temp folders.';
            fixture.TeardownDescription = ...
                'Restored MATLAB path and PROTEUS path configuration.';
        end

        function [tf, missing] = meetsRequirements(fixture, requires)
            %MEETSREQUIREMENTS True if all named requirements are met.
            missing = {};
            for k = 1:numel(requires)
                switch requires{k}
                    case 'kWave'
                        ok = ~isempty(fixture.KWavePath);
                    case 'Statistics'
                        ok = fixture.HasStatistics;
                    otherwise
                        error('Unknown requirement %s.', requires{k});
                end
                if ~ok
                    missing{end+1} = requires{k}; %#ok<AGROW>
                end
            end
            tf = isempty(missing);
        end
    end

    methods (Access = protected)
        function tf = isCompatible(~, ~)
            tf = true;
        end
    end
end

function tf = supports_local_paths(root)
tf = contains(fileread(fullfile(root,'path_setup.m')), 'PROTEUS_LOCAL_PATHS');
end

function redirect_with_environment(fixture, custom)
file = fullfile(fixture.TempRoot,'proteus_local_paths.m');
names = fieldnames(custom);
lines = cell(numel(names),1);
for n = 1:numel(names)
    lines{n} = sprintf('PATHS_LOCAL.%s = ''%s'';', names{n}, ...
        strrep(custom.(names{n}),'''',''''''));
end
write_text(file, strjoin(lines, newline));
old = getenv('PROTEUS_LOCAL_PATHS');
setenv('PROTEUS_LOCAL_PATHS', file);
fixture.addTeardown(@setenv, 'PROTEUS_LOCAL_PATHS', old);
end

function redirect_with_paths_mat(fixture, custom)
% Legacy code versions: temporarily replace the tracked PATHS.mat.
pathsFile = fullfile(fixture.RepoRoot,'PATHS.mat');
backup    = fullfile(fixture.RepoRoot,'PATHS.mat.test-backup');
if isfile(backup)
    error(['%s exists: a previous test run did not restore PATHS.mat. ' ...
        'Restore it (git checkout PATHS.mat) and delete the backup.'], backup)
end
movefile(pathsFile, backup);
fixture.addTeardown(@movefile, backup, pathsFile, 'f');

S = load(backup,'-mat','PATHS');
T = S.PATHS;
map = {'k-Wave','kWavePath'; 'k-Wave binaries','BinaryPath'; ...
    'Flow geometry data','GeometriesPath'; ...
    'Ground truth frames','GroundTruthPath'; 'H5 files','DataPath'; ...
    'Results','ResultsPath'; 'Simulation settings','SettingsPath'};
for n = 1:size(map,1)
    T.Path{strcmp(T.Description, map{n,1})} = custom.(map{n,2});
end
PATHS = T; %#ok<NASGU>
save(pathsFile,'PATHS');
end

function write_text(file, text)
fid = fopen(file,'w');
fprintf(fid,'%s\n',text);
fclose(fid);
end

function write_tiny_geometry(geometriesPath)
% A synthetic 2 mm cubic flow geometry without vessel (no STL needed).
folder = fullfile(geometriesPath,'tiny_box');
mkdir(folder);
BoundingBox = struct('Xmin',0,'Xmax',2e-3,'Ymin',-1e-3,'Ymax',1e-3, ...
    'Zmin',-1e-3,'Zmax',1e-3); %#ok<NASGU>
EmbedVessel = false; %#ok<NASGU>
Rotation = eye(3); %#ok<NASGU>
STLfile = 'none.stl'; %#ok<NASGU>
STLunit = 1; %#ok<NASGU>
Visualization = struct('Image','none.png','Fraction',1); %#ok<NASGU>
save(fullfile(folder,'GeometryProperties.mat'), 'BoundingBox', ...
    'EmbedVessel','Rotation','STLfile','STLunit','Visualization');
end
