function SimulationParameters = update_simulation_parameters(...
    SimulationParameters, Medium, f0)
% SimulationParameters: struct with simulation parameters
% f0: transmit frequency

CFL     = SimulationParameters.CFL;     % Courant-FriedrichsLewy number
ppwl	= SimulationParameters.PointsPerWavelength;
in_var  = SimulationParameters.IndependentVariable;

% Points per wavelength for the highest speed of sound:
ppwl = ppwl*Medium.SpeedOfSoundMaximum/Medium.SpeedOfSound;

switch in_var
    case 'CFL'
        SimulationParameters.SamplingRate = f0*ppwl/CFL;
        
    case 'Sampling rate'
        fs = SimulationParameters.SamplingRate;
        SimulationParameters.CFL = f0*ppwl/fs;
end


end