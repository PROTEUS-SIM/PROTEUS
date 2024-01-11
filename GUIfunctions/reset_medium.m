function Medium = reset_medium()

% Assign the properties of the bulk tissue:
Medium.Tissue = 'General tissue';
Medium.Inhomogeneity = 0.02;               % (standard deviation)
Medium = assign_medium_properties(Medium);

% Cutoff of speed of sound and density variation (standard deviations):
Medium.InhomogeneityCutoff = 2;

% Assign the properties of blood:
Vessel.Tissue = 'Blood';
Vessel = assign_medium_properties(Vessel);
Vessel = assign_liquid_properties(Vessel,Vessel.Tissue);

Medium.Vessel = Vessel;

% Medium minimum speed of sound for filtering purposes:
Medium = compute_sound_speed_extrema(Medium);

% Save the k-Wave medium when running the simulation
Medium.Save = true;

% REFERENCES

% Haim Azhari, “Appendix A: Typical acoustic properties of tissues,” in
% Basics of Biomedical Ultrasound for Engineers, pp. 313–314, John Wiley & 
% Sons, Inc., 2010.

end