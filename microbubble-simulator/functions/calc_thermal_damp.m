function [nuth, kappa] = calc_thermal_damp(liquid,gas,bubble,shell,w)
% Computes thermal damping parameter and effective polytropic exponent,
% following: A. Prosperetti, J. Acoust. Soc. Am, 61(1), January 1977

%% MATERIAL PROPERTIES
% Liquid properties
kl      = liquid.k;     % Thermal conductivity (W/m/K)
rhol    = liquid.rho;   % Density (kg/m^3)
T0      = liquid.T0;    % Initial temperature
Pat     = liquid.P0;    % Ambient pressure (Pa)
cvl     = liquid.cp;    % Specific heat constant volume (J/kg/K)
% (For a liquid cv is approximately cp)

% Gas properties
kg      = gas.k;        % Thermal conductivity (W/m/K)
cpg     = gas.cp;       % Specific heat (J/kg/K)
gam     = gas.gam;      % Heat capacity ratio
cvg     = cpg/gam;      % Specific heat constant volume (J/kg/K)
Mg      = gas.Mg;       % Molar mass (kg/mol)
rhog    = gas.rho;      % Density (kg/m^3)

Rg      = 8.314;      	% Gas constant (J/K/mol)

% Microbubble and shell properties
R0      = bubble.R0;    % Initial microbubble radius (m)
sig_0   = shell.sig_0;  % Initial surface tension (N/m)

% Compute equilibrium density:
P_eq = Pat + 2*sig_0/R0;        % Equilibrium pressure
rhog = P_eq/Pat*rhog;           % Equilibrium density (isothermal compr.)

%% Compute thermal damping constant and polytropic exponent
Dg = kg/rhog/cvg;   % thermal diffusivity gas, page 19
Dl = kl/rhol/cvl;   % thermal diffusivity liquid, page 19

G1 = Mg*Dg*w/gam/Rg/T0;     % page 19
G2 = w*R0^2/Dg;             % page 19
G3 = w*R0^2/Dl;             % page 19

% Equation 17, page 19:
beta1  = sqrt(1/2*gam*G2*(1i - G1 + sqrt((1i-G1)^2 + 4i*G1/gam)));
beta2  = sqrt(1/2*gam*G2*(1i - G1 - sqrt((1i-G1)^2 + 4i*G1/gam)));

lamb1  = beta1*coth(beta1)-1;     
lamb2  = beta2*coth(beta2)-1;   

Gamma1 = 1i + G1 + sqrt((1i-G1)^2 + 4i*G1/gam);  
Gamma2 = 1i + G1 - sqrt((1i-G1)^2 + 4i*G1/gam); 

f = 1+(1+1i)*sqrt(G3/2);

% Approximations to Equation 17 (Eq. 18, p. 19):
% beta1  = (1+1i)*sqrt(gam*G2/2)*(1+1i/2*(gam-1)/gam*G1);
% beta2  = sqrt(G1*G2)*(1i+1/2*(gam-1)/gam*G1);
% 
% Gamma1 = 2*(1i+G1/gam);
% Gamma2 = 2*(gam-1)/gam*G1;

k = kl/kg;

% Equation 16, page 19:
phi = (k*f*(Gamma2-Gamma1)+lamb2*Gamma2-lamb1*Gamma1)/...
    (k*f*(lamb2*Gamma1-lamb1*Gamma2)-lamb1*lamb2*(Gamma2-Gamma1));  

nuth = 1/4*w*rhog*R0^2*imag(phi);               % Eq. 14
kappa = 1/3*(w^2*rhog*R0^2/P_eq)*real(phi);     % Eq. 15

end



