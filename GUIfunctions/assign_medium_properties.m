function Medium = assign_medium_properties(Medium)
% Load tissue properties

if strcmp(Medium.Tissue,'General tissue')

Medium.SpeedOfSound     = 1540; % m/s
Medium.Density          = 1000; % kg/m^3
Medium.BonA             = 6;   
Medium.AttenuationA     = 0.75;
Medium.AttenuationB     = 1.5;

elseif ~strcmp(Medium.Tissue,'Custom')
    
    % Tissue properties from:
 	% Haim Azhari, “Appendix A: Typical acoustic properties of tissues,” in
    % Basics of Biomedical Ultrasound for Engineers, pp. 313–314, 
    % John Wiley & Sons, Inc., 2010.
    
    Tissues = load('tissue_properties.mat');
    tissue_names        = Tissues.tissue_names;
    tissue_properties   = Tissues.tissue_properties;
    

    % Find the tissue name in the list of tissue names:
    found = 0;
    for i = 1:length(tissue_names)
        if ~isempty(strfind(tissue_names{i} ,Medium.Tissue))
            found = 1;
            break
        end
    end
    
    % Assign the tissue properties to the output:
    if found ==0
        error('Tissue not found');
    else       
        Medium.Density          = tissue_properties(i,1)*1000;  % kg/m^3
        Medium.SpeedOfSound     = tissue_properties(i,2);       % m/s
        Medium.AttenuationA     = tissue_properties(i,4);
        Medium.AttenuationB     = tissue_properties(i,5);
        Medium.BonA             = tissue_properties(i,6);
        
    end
    
end
    
end