function [out, resultDir, settingsFile] = run_rf_simulation(env, S, name)
%RUN_RF_SIMULATION Run main_RF on the settings S with one synthetic
%ground-truth frame per acquisition frame and return the RF data and the
%k-Wave medium.
P = env.PATHS;
settingsFile = fullfile(P.SettingsPath,[name '.mat']);
write_settings(S, P, settingsFile);
write_synthetic_ground_truth(fullfile(P.GroundTruthPath,name), S, 1);
rng(0,'twister'); % define_medium draws a random scatterer background
main_RF(settingsFile, name, name);
resultDir = fullfile(P.ResultsPath, name);
files = dir(fullfile(resultDir,'Frame_*.mat'));
for k = 1:numel(files)
    F = load(fullfile(resultDir,files(k).name),'RF','dt');
    out.RF{k} = F.RF;
    out.dt    = F.dt;
end
M = load(fullfile(resultDir,'medium.mat'),'medium');
out.medium_sound_speed = M.medium.sound_speed;
out.medium_density     = M.medium.density;
end
