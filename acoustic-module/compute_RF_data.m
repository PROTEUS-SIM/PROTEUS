function [RF, run_param] = compute_RF_data(Transducer, sensor_data, ...
    sensor_weights, Grid, run_param)
%COMPUTE_RF_DATA Wrapper function for compute_RF. 
% If run_param.DATA_CAST_RF is of GPU type, but insufficient resources can
% be allocated on the GPU to complete compute_RF, run_param.DATA_CAST_RF is
% changed to CPU type.
%
% See also compute_RF.
%
% Nathan Blanken, University of Twente, 2023

try
    RF = compute_RF(Transducer,sensor_data,sensor_weights,Grid,run_param);
catch ME
    % If the exception is an out-of-memory issue, switch to GPU, otherwise
    % rethrow it.
    if contains(ME.identifier, 'parallel:gpu:array:OOM')
        disp([...
            'WARNING: Out of memory on GPU device. MATLAB was ' ...
            'unable to allocate sufficient resources on the ' ...
            'GPU to complete the RF computation.'])
        disp('Switching to CPU.');
    else
        rethrow(ME)
    end
    
    % Change the data cast for the RF data from GPU to CPU:
    switch run_param.DATA_CAST_RF
        case 'gpuArray-double'
            run_param.DATA_CAST_RF = 'double';
        case 'gpuArray-single'
            run_param.DATA_CAST_RF = 'single';
    end

    % Retry the RF computation on the CPU:
    RF = compute_RF(Transducer,sensor_data,sensor_weights,Grid,run_param);
end

end