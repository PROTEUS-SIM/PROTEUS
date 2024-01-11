function Medium = compute_sound_speed_extrema(Medium)
% Medium minimum speed of sound for filtering purposes.

cutoff = Medium.InhomogeneityCutoff; 
inhom  = Medium.Inhomogeneity;

cmin = Medium.SpeedOfSound*(1-inhom*cutoff);
cmax = Medium.SpeedOfSound*(1+inhom*cutoff);

Medium.SpeedOfSoundMinimum = min(cmin, Medium.Vessel.SpeedOfSound);
Medium.SpeedOfSoundMaximum = max(cmax, Medium.Vessel.SpeedOfSound);

end