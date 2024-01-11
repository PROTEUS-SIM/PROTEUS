function write_to_file(Microbubble,SimulationParameters,Geometry,...
    Transducer,Acquisition,Medium,Transmit,PATHS,filename)
% Add the grid size, the element delays, the apodization, and the
% microbubble radii to the GUI output parameters. Update the simulation
% domain. Write all GUI parameters to file.
%
% Nathan Blanken, University of Twente, 2022

% Compute the grid size:
c    = Medium.SpeedOfSound;
f0   = Transmit.CenterFrequency;
ppwl = SimulationParameters.PointsPerWavelength;

grid_spacing = c/(f0*ppwl);
SimulationParameters.GridSize = grid_spacing;

% Compute delays
if strcmp(Transmit.DelayType,'Compute delays')
    Transmit = compute_delays(Transmit,Transducer,Medium);
end

% Assign apodization
if strcmp(Transmit.ApodizationType,'Uniform apodization')
    Transmit.Apodization = ones(1,Transducer.NumberOfElements);
end

% Save the GUI parameters:
if isempty(filename)
filename = 'GUI_output_parameters.mat';
filename = fullfile(PATHS.SettingsPath,filename);

    uisave({'Microbubble','SimulationParameters','Geometry',...
        'Transducer','Acquisition','Medium','Transmit'},filename)
else
    save(filename,'Microbubble','SimulationParameters','Geometry',...
        'Transducer','Acquisition','Medium','Transmit')
end

end