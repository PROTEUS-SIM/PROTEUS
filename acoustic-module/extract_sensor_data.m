function [sensor_data_MB, sensor_data_trans] = extract_sensor_data(...
    sensor_data, mask_idx, mask_idx_trans, mask_idx_MB, param, kgrid)
% Split sensor data into microbubble sensor data and transducer sensor 
% data.

% Time needed to reach all the microbubbles in the first iteration
t_end_1 = param.tr(1);

% Maximum sensor signal length needed for microbubbles:
Nt = floor(t_end_1 / kgrid.dt) + 1;  

[~,sensor_data_MB_idx,~]    = intersect(mask_idx,mask_idx_MB);
[~,sensor_data_Trans_idx,~] = intersect(mask_idx,mask_idx_trans);

sensor_data_MB.p     = sensor_data.p(sensor_data_MB_idx,1:Nt);
sensor_data_trans.p  = sensor_data.p(sensor_data_Trans_idx,:);

end