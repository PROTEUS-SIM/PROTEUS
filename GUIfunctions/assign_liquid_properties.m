function Liquid = assign_liquid_properties(Liquid,type)
% Assign thermodynamic properties of the specified liquid.
%
% REFERENCES
%
% Nader et al., Front. Physiol., 17 October 2019, Sec. Red Blood Cell 
% Physiology, https://doi.org/10.3389/fphys.2019.01329
%
% Rosina et al., Physiol. Res. 56 (Suppl. 1): S93-S98, 2007, 
% https://doi.org/10.33549/physiolres.931306
%
% Xu, F., Lu, T.J. & Seffen, K.A. Biothermomechanical behavior of skin 
% tissue. Acta Mech. Sin. 24, 1–23 (2008). 
% https://doi.org/10.1007/s10409-007-0128-8
%
% https://itis.swiss/virtual-population/tissue-properties/database/
% thermal-conductivity/
%
% Reitman, M.L. (2018), Of mice and men – environmental temperature, body 
% temperature, and treatment of obesity. FEBS Lett, 592: 2098-2107. 
% https://doi.org/10.1002/1873-3468.13070
%
% Thermophysical Properties of Fluid Systems, NIST Chemistry WebBook
% https://webbook.nist.gov/chemistry/fluid/

switch type
    case 'Blood'
        % Additional properties of blood for the microbubble module:
        Liquid.ThermalConductivity = 0.52;      % [W/m/K] (itis.swiss)
        Liquid.SpecificHeat        = 3770;      % [J/kg/K] (Xu et al.)
        Liquid.DynamicViscosity    = 4.5e-3;    % [Pa.s] (Nader et al.)
        Liquid.SurfaceTension      = 0.053;     % @ 37 deg C [N/m] (Rosina)
        Liquid.Temperature         = 310;       % [K] (Reitman)
        Liquid.Pressure            = 1.013e5;   % Atmospheric pressure [Pa]
        
    case 'Water'
        Liquid.ThermalConductivity = 0.6;       % [W/m/K] @ 20 deg C
        Liquid.SpecificHeat        = 4184;      % [J/kg/K] @ 20 deg C 
        Liquid.DynamicViscosity    = 1e-3;      % [Pa.s] @ 20 deg C 
        Liquid.SurfaceTension      = 0.072;     % [N/m]
        Liquid.Temperature         = 293;       % Room temperature [K]
        Liquid.Pressure            = 1.013e5;   % Atmospheric pressure [Pa]
end

end