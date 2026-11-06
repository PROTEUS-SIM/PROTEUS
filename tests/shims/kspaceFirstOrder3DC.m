function sensor_data = kspaceFirstOrder3DC(kgrid, medium, source, sensor, varargin)
%KSPACEFIRSTORDER3DC Test double for the k-Wave C++ solver.
%
% Forwards the call to the MATLAB solver kspaceFirstOrder3D so that the
% tests run without compiled k-Wave binaries. Options that only exist for
% the C++/CUDA solvers are dropped, and plotting is disabled.

binaryOnly = {'BinaryPath','BinaryName','DataPath','DataName', ...
    'DeleteData','DeviceNum','FunctionName','NumThreads', ...
    'SystemCall','ThreadBinding','Verbose','CheckpointFile', ...
    'CheckpointInterval','CheckpointTimesteps'};

args = {};
for k = 1:2:numel(varargin)
    if ~any(strcmpi(varargin{k}, binaryOnly))
        args = [args varargin(k:k+1)]; %#ok<AGROW>
    end
end

sensor_data = kspaceFirstOrder3D(kgrid, medium, source, sensor, ...
    args{:}, 'PlotSim', false);

% The C++ solver returns sensor data in the same format as the MATLAB
% solver when sensor.record is used; no reshaping needed.
end
