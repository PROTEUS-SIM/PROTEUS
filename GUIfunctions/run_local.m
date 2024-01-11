function run_local(savedir, savename, folder, sim_mode)

switch sim_mode
    case 'RF data'
        
        filename = 'GUI_output_parameters.mat';
        main_RF([savedir filesep filename], folder, savename)
        
    case 'Pressure map'
        
        filename = 'GUI_output_parameters.mat';
        main_pressure_field([savedir filesep filename], savename)
        
        filename = 'pressure_maps.mat';
        load([savedir filesep filename],...
            'Grid','sensor_data_xy','sensor_data_xz')

        figure()
        imagesc(Grid.y,Grid.x,sensor_data_xy.p_max)
        xlabel('Lateral coordinate (m)')
        ylabel('Axial coordinate (m)')
        title('Lateral plane')

        figure()
        imagesc(Grid.z,Grid.x,sensor_data_xz.p_max)
        xlabel('Elevation coordinate (m)')
        ylabel('Axial coordinate (m)')
        title('Axial plane')

        msgbox(['Pressure maps saved in ' savedir])
end

end