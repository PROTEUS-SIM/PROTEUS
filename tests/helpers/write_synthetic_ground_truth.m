function folder = write_synthetic_ground_truth(folder, S, seed)
%WRITE_SYNTHETIC_GROUND_TRUTH Write deterministic microbubble frames.
%
% Writes FlowSimulationParameters.mat and Frame_XX.mat files in the same
% format as generate_streamlines, with microbubbles uniformly distributed
% in the bounding box of the geometry in S.Geometry. No flow data needed.

if nargin < 3
    seed = 1;
end
stream = RandStream('mt19937ar','Seed',seed);

if ~isfolder(folder)
    mkdir(folder);
end

Acq = S.Acquisition;
MB  = S.Microbubble;
BB  = S.Geometry.BoundingBox;
lo  = transpose(BB.Center - BB.Diagonal/2);
hi  = transpose(BB.Center + BB.Diagonal/2);

FlowSimulationParameters.TimeBtwPulse   = Acq.TimeBetweenPulses;
FlowSimulationParameters.FrameRate      = Acq.FrameRate;
FlowSimulationParameters.NBPulses       = Acq.NumberOfPulses;
FlowSimulationParameters.NMicrobubbles  = MB.Number;
FlowSimulationParameters.NumberOfFrames = Acq.NumberOfFrames;
FlowSimulationParameters.Microbubble    = MB;
save(fullfile(folder,'FlowSimulationParameters.mat'), ...
    'FlowSimulationParameters');

N = MB.Number;
num_padding = num2str(length(num2str(Acq.NumberOfFrames)));
for m = 1:Acq.NumberOfFrames
    Frame = struct();
    for n = 1:Acq.NumberOfPulses
        % Keep a margin so that bubbles stay inside the domain:
        u = 0.1 + 0.8*rand(stream, N, 3);
        pulse = ['Pulse' num2str(n)];
        Frame.(pulse).Points       = lo + u.*(hi - lo);
        Frame.(pulse).Velocity     = 1e-3*randn(stream, N, 3);
        Frame.(pulse).Radius       = 1e-6*(1 + 2*rand(stream, N, 1));
        Frame.(pulse).StreamNumber = (1:N)';
    end
    file_name = ['Frame_' num2str(m,['%0' num_padding 'i']) '.mat'];
    save(fullfile(folder,file_name),'Frame');
end
end
