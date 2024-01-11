function RF = compute_RF(Transducer, sensor_data, sensor_weights, ...
    Grid, run_param)
%COMPUTE_RF Convert pressure sensor data on the transducer to voltage
%element data.
%
% Nathan Blanken, University of Twente, 2023

% Get number of transducer elements, number of integration points per
% element and number of dimensions:
[N_el,N_int,~] = size(Transducer.integration_points);
M = size(sensor_data.p,2); % Signal length

% Get data casting properties:
switch run_param.DATA_CAST_RF
    case 'gpuArray-single'
        dataType = 'single';
        useGPU   = true;
    case 'gpuArray-double'
        dataType = 'double';
        useGPU   = true;
    case 'single'
        dataType = 'single';
        useGPU   = false;
    case 'double'
        dataType = 'double';
        useGPU   = false;
end

apod   = Transducer.integration_receive_apodization;
delays = Transducer.integration_receive_delays(:);
apod   = cast(apod,  dataType);
delays = cast(delays,dataType);

% Compute signal length required to apply the delays:
N = M + ceil(max(delays)/Grid.dt);

% Get a signal length with small prime factors:
max_expansion = max(10,round(N*0.05));
max_prime = 5;
N = optimize_grid_size(N, [0 max_expansion], max_prime);

% Sensed pressure at integration points:
disp('Computing pressure at transducer integration points ...')
if useGPU
    sensor_weights = gpuArray(sensor_weights);
    sensor_data.p  = gpuArray(sensor_data.p);
else 
    sensor_data.p  = gather(sensor_data.p);
end
p = sensor_weights*double(sensor_data.p);
p = cast(p,dataType);

% Set up frequency axis (Hz)
f = (0:(N-1))/(N*Grid.dt);
f = cast(f,dataType);

% Make symmetric around N/2 to keep time-domain signal real:
f(:,ceil(N/2+1):N) = -(f(:,floor(1+N/2):-1:2));

% Time shift in the frequency domain:
disp('Applying lens delays ...')
if useGPU
    delays = gpuArray(delays); 
    f      = gpuArray(f); 
    apod   = gpuArray(apod); 
end
p = fft(p,N,2);
p = p.*exp(-2*pi*1i*delays*f);
p = ifft(p,[],2,'symmetric');

% Apply the receive apodization:
p = reshape(p,N_el,N_int,N).* apod;

% Compute the average pressure for each element:
p = reshape(mean(p,2),N_el,N);

if useGPU; p = gather(p); end

% Convolution with receive impulse response
IR = resample_signal(Transducer.ReceiveImpulseResponse, ...
    Transducer.SamplingRate, 1/Grid.dt, false);

disp('Computing RF data ...')
RF = convn(p,IR)*Grid.dt;

end