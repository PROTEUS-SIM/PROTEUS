function [savedir, savename, folder, status_msg] = ...
    run_local_setup(...
    sim_mode,...
    Acquisition,...
    Geometry,...
    Medium,...
    Microbubble,...
    SimulationParameters,...
    Transducer,...
    Transmit,...
    PATHS)
        
% Path to results:
ResultsPath = PATHS.ResultsPath;

savename = datestr(now,'yy_mm_dd_hh_MM');
savedir  = [ResultsPath filesep savename];

if ~isfolder(savedir)
    mkdir(savedir)
end

% Auto-save the GUI parameters:
filename = 'GUI_output_parameters.mat';
filename = [savedir filesep filename];

write_to_file(Microbubble,SimulationParameters,Geometry,...
    Transducer,Acquisition,Medium,Transmit,PATHS,filename)

switch sim_mode
    case 'RF data'
        status_msg = 'Simulating RF data.';
               
        folder = Acquisition.Folder;
        
        if isempty(folder)
            
            folder = savename;
            save_path = [PATHS.GroundTruthPath filesep folder];
            
            showStreamlines = false;
            
            generate_streamlines(Geometry, Microbubble, Acquisition, ...
                PATHS, folder, showStreamlines)
            
            save_path_msg = ['Microbubble ground truth frames saved in:'...
                newline save_path '.' newline];
            
            disp(save_path_msg)
        end
        
    case 'Pressure map'
        status_msg = 'Simulating pressure map.';
        folder = '';
end

end