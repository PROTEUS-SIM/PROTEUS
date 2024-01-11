function [liquid, gas] = getMaterialProperties()

% Material properties of water and perfluorobutane
% Nathan Blanken, University of Twente, 2020

liquid.k = 0.6;     	% Thermal conductivity water  at 20 deg C (W/m/K)
liquid.rho = 998;   	% Density water at 20 deg C (kg/m^3)
liquid.cp = 4186;   	% Specific heat water at 20 deg C in J/kg/K
liquid.nu = 1e-3;    	% Dynamic viscosity water at 20 deg C (Pa.s)
liquid.c = 1480;    	% Speed of sound in water at 20 deg C (m/s)
liquid.sig = 0.072;     % Surface tension of water (N/m)

gas.k = 0.0138;     	% Thermal conductivity PFB (W/m/K) from F2 chemical
gas.rho =  10.1;        % Density PFB (C4F10) (kg/m^3)
gas.Mg = 0.238;         % Molar mass PFB (kg/mol)
gas.gam = 1.07;         % Heat capacity ratio PFB
gas.cp  = 809;          % Specific heat PFB (J/kg/K) (F2 chemical):

% Rg = 8.314;         	% gas constant (J/K/mol)
% Specific heat PFB (J/kg/K) (assuming ideal gas):
% gas.cp = gas.gam/(gas.gam-1)*Rg/gas.Mg;	

liquid.T0 = 293;      	% Initial temperature (K)
liquid.P0 = 1.013e5;  	% Ambient pressure (Pa)

% Acoustic properties
% According to "Basics of Biomedical Ultrasound for Engineers",
% Haim Azhari: 
liquid.a = 0.002;
liquid.b = 2;

liquid.BA   = 5.2;               % Nonlinear parameter water
liquid.beta = 1 + liquid.BA/2;
end

