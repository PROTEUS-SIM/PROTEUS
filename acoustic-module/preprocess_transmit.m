function Transmit = preprocess_transmit(Transmit,Medium,kgrid)
% Filter and resample transmit signal.

p = Transmit.PressureSignal;
V = Transmit.VoltageSignal;

% Filter settings:
Filter.dt          = 1/Transmit.SamplingRate;
Filter.t_array     = [];
Filter.k_max       = kgrid.k_max;
Filter.TW          = 0.1/(Transmit.SamplingRate*kgrid.dt);
Filter.sound_speed = Medium.SpeedOfSoundMinimum;

% Filter out unsupported frequencies   
p_filt = filterTimeSeries(Filter, Filter, p,...
    'ZeroPhase',true,'TransitionWidth',Filter.TW,'PPW',2);

V_filt = filterTimeSeries(Filter, Filter, V,...
    'ZeroPhase',true,'TransitionWidth',Filter.TW,'PPW',2);

% resample the signal to kWave sampling frequency
fs_old = Transmit.SamplingRate;
fs_new = 1/kgrid.dt;

p_resamp = resample_signal(p_filt, fs_old, fs_new, false);
V_resamp = resample_signal(V_filt, fs_old, fs_new, false);
Transmit.SamplingRate = fs_new;

Transmit.PressureSignal = p_resamp;
Transmit.VoltageSignal  = V_resamp;

end