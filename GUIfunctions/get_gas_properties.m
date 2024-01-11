function Gas = get_gas_properties(Gas)
% Properties from NIST webbook:
% https://webbook.nist.gov/chemistry/fluid/
% Retrieved on 12th August 2022
%
% At 1 atm
% At 37 deg C

switch Gas.Type
    case 'Sulfur hexafluoride'
        
        Gas.ThermalConductivity = 0.0139; % (W/m/K)
        Gas.Density             = 5.80;   % (kg/m^3)
        Gas.MolarMass           = 0.146;  % (kg/mol)
        Gas.SpecificHeat        = 687;    % Constant pressure (J/kg/K) 
        Gas.HeatCapacityRatio   = 1.09;
        
    case 'Perfluoropropane'
        
        Gas.ThermalConductivity = 0.0132; % [W/m/K]
        Gas.Density             = 7.53;   % [kg/m^3]
        Gas.MolarMass           = 0.188;  % [kg/mol]
        Gas.SpecificHeat        = 814;    % Constant pressure [J/kg/K]
        Gas.HeatCapacityRatio   = 1.06;
        
    case 'Perfluorobutane'
        
        Gas.ThermalConductivity = 0.0136; % [W/m/K]
        Gas.Density             = 9.64;   % [kg/m^3]
        Gas.MolarMass           = 0.238;  % [kg/mol]
        Gas.SpecificHeat        = 883;    % Constant pressure [J/kg/K]
        Gas.HeatCapacityRatio   = 1.05;
        
    otherwise
        error('Gas not found')
end

end