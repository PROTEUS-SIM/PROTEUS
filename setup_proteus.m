function PATHS = setup_proteus(options)
%SETUP_PROTEUS Check the PROTEUS installation and add it to the MATLAB path.
%
% SETUP_PROTEUS() checks all dependencies, prints a report, and adds the
% PROTEUS modules and k-Wave to the MATLAB path for this session.
%
% SETUP_PROTEUS('InstallKWave',true) first downloads k-Wave 1.4.1 from
% GitHub (https://github.com/ucl-bug/k-wave) into external/k-wave if it is
% not installed yet. The k-Wave C++/CUDA binaries are not included; get
% them from http://www.k-wave.org/download.php (see README.md).
%
% PATHS = SETUP_PROTEUS(...) returns the struct of paths from path_setup.

arguments
    options.InstallKWave (1,1) logical = false
end

root = fileparts(mfilename('fullpath'));
kWaveVersion = '1.4.1';

fprintf('\nPROTEUS setup (%s)\n\n', root);

%--------------------------------------------------------------------------
% k-Wave
%--------------------------------------------------------------------------
defaultKWave = fullfile(root,'external','k-wave','k-Wave');
if options.InstallKWave && ~isfolder(defaultKWave)
    install_kwave(root, kWaveVersion);
end

%--------------------------------------------------------------------------
% Paths (errors with an explanation if a required folder is missing)
%--------------------------------------------------------------------------
addpath(root)
PATHS = path_setup();

addpath(PATHS.GUIfunctions, PATHS.StreamlineFunctions, ...
    PATHS.AcousticModulePath, PATHS.MicrobubblePath, ...
    fullfile(PATHS.MicrobubblePath,'functions'), ...
    PATHS.VoxelisationPath, fullfile(root,'delay-and-sum'), ...
    PATHS.kWavePath);

report('MATLAB release', true, version('-release'));
report('k-Wave', true, PATHS.kWavePath);

%--------------------------------------------------------------------------
% Toolboxes
%--------------------------------------------------------------------------
report('Signal Processing Toolbox', has_product('signal', ...
    'Signal_Toolbox'), 'required');
report('Statistics and Machine Learning Toolbox', has_product('stats', ...
    'Statistics_Toolbox'), 'optional (only used by the test suite)');
report('Parallel Computing Toolbox', has_product('parallel', ...
    'Distrib_Computing_Toolbox'), ...
    'optional (GPU simulations, parallel microbubble batches)');

%--------------------------------------------------------------------------
% k-Wave binaries
%--------------------------------------------------------------------------
if ispc
    omp = 'kspaceFirstOrder-OMP.exe'; cuda = 'kspaceFirstOrder-CUDA.exe';
else
    omp = 'kspaceFirstOrder-OMP';     cuda = 'kspaceFirstOrder-CUDA';
end
report('k-Wave C++ binary (solver 3DC)', ...
    isfile(fullfile(PATHS.BinaryPath,omp)), ...
    ['optional, ' fullfile(PATHS.BinaryPath,omp)]);
report('k-Wave CUDA binary (solver 3DG)', ...
    isfile(fullfile(PATHS.BinaryPath,cuda)), ...
    ['optional, ' fullfile(PATHS.BinaryPath,cuda)]);

%--------------------------------------------------------------------------
% Data and optional tools
%--------------------------------------------------------------------------
geometryFolder = fullfile(PATHS.GeometriesPath,'renal_tree');
hasGeometry = false;
if isfile(fullfile(geometryFolder,'GeometryProperties.mat'))
    G = load(fullfile(geometryFolder,'GeometryProperties.mat'),'STLfile');
    hasGeometry = isfile(fullfile(geometryFolder,G.STLfile));
end
report('Flow geometry renal_tree (default)', hasGeometry, ...
    'download from Zenodo, see README.md');
report('vtkToolbox', isfolder(fullfile(PATHS.VtkToolboxPath,'MATLAB')), ...
    'optional, only for converting new VTU flow data');

fprintf('\nPROTEUS modules added to the MATLAB path. Start the GUI with: MainGUI\n\n');
end


function report(name, ok, detail)
if ok; status = 'OK     '; else; status = 'MISSING'; end
fprintf('  [%s] %-42s %s\n', status, name, detail);
end


function tf = has_product(verName, licenseName)
tf = ~isempty(ver(verName)) && license('test', licenseName);
end


function install_kwave(root, kWaveVersion)
url = sprintf('https://github.com/ucl-bug/k-wave/archive/refs/tags/v%s.zip', ...
    kWaveVersion);
target = fullfile(root,'external');
if ~isfolder(target); mkdir(target); end
if isfolder(fullfile(target,'k-wave'))
    error(['%s exists but does not contain k-Wave/. Remove it and run ' ...
        'setup_proteus(''InstallKWave'',true) again.'], ...
        fullfile(target,'k-wave'))
end
fprintf('Downloading k-Wave %s from %s ...\n', kWaveVersion, url);
zipFile = websave(fullfile(tempdir,'k-wave.zip'), url);
cleanup = onCleanup(@() delete(zipFile));
unzip(zipFile, target);
movefile(fullfile(target,['k-wave-' kWaveVersion]), fullfile(target,'k-wave'));
fprintf('k-Wave installed in %s.\n\n', fullfile(target,'k-wave'));
end
