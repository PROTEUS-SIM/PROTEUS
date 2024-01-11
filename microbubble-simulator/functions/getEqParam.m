function eqparam = getEqParam(liquid, gas, shell, bubble, pulse)
% Compute the damping constants and the polytropic exponent.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATERIAL AND PULSE PROPERTIES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nu_l    = liquid.nu;    % Dynamic viscosity liquid (Pa.s)
rhol    = liquid.rho;   % Density liquid (kg/m^3)
c       = liquid.c;     % Speed of sound (m/s)
P0      = liquid.P0;    % Ambient pressure (Pa)

gam     = gas.gam;      % Heat capacity ratio gas
R0      = bubble.R0;    % Initial microbubble radius (m)

sig_0   = shell.sig_0;  % Initial surface tension (N/m)
Ks      = shell.Ks;     % Surface dilatational viscosity (N.s/m)

w       = pulse.w;      % Angular frequency pulse (Hz)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THERMAL MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The thermal model by Prosperetti only works for an oscillating field:
if strcmp(liquid.ThermalModel,'Prosperetti') && w == 0
  error('Prosperetti model only valid for w>0')
end
    
% Thermal damping and polytropic exponent
switch liquid.ThermalModel
    case 'Prosperetti'
        % Thermal model, Prosperetti, JASA, 61, 1977
        [eqparam.nu_th, eqparam.kappa] = calc_thermal_damp(...
            liquid,gas,bubble,shell,w);

    case 'Adiabatic'
        eqparam.nu_th =0;
        eqparam.kappa = gam;% Polytropic exponent 

    case 'Isothermal'
        eqparam.nu_th=0;
        eqparam.kappa = 1;% Polytropic exponent
        
    otherwise
        error('Thermal model not recognized')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VISCOUS DAMPING AND THERMAL DAMPING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eqparam.nu_vis = nu_l;   

% Effective viscosity linear model  	
eqparam.nu = eqparam.nu_vis + eqparam.nu_th;  % Effective viscosity (Pa.s)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RADIATION DAMPING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Only set RadiationDamping = true, if the Rayleigh-Plesset equation does
% not account for reradiation itself:
RadiationDamping = false;

% Radiation damping, Prosperetti, JASA, 61, 1977?p.18, Eq. 10 - 12
x = w*R0/c;
eqparam.nu_rad = rhol*R0^2/4*(x/(1+x^2))*w;

if RadiationDamping==true
    eqparam.nu = eqparam.nu + eqparam.nu_rad;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETERS FOR LINEARISED RAYLEIGH-PLESSET EQUATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The parameters below should only be used in a linear microbubble dynamics
% model, not in the full, nonlinear, Rayleigh-Plesset equation.

% If the shell stiffness has not been defined or computed before, compute
% the stiffness from the slope of the surface tension curve. See 
% Marmottant et al., J. Acoust. Soc. Am. 118 6, 2005.
if ~isfield(shell,'chi')
    epsilon = 0.001;
    sig1 = calc_surface_tension(R0*(1-epsilon),shell);
    sig2 = calc_surface_tension(R0*(1+epsilon),shell);
    chi = (sig2-sig1)/epsilon/4;
else
    chi = shell.chi;
end

eqparam.chi = chi;

% Compute the resonance frequency according to S.M. van der Meer et al., 
% J. Acoust. Soc. Am, 121 (1), January 2007.
omega_0 = sqrt(1/(rhol*R0^2)*...
    (3*eqparam.kappa*(P0 + 2*sig_0/R0) - 2*sig_0/R0 + 4*chi/R0));

eqparam.omega_0 = omega_0;

% Compute damping constants according to S.M. van der Meer et al., 
% J. Acoust. Soc. Am, 121 (1), January 2007.
eqparam.delta_vis = 4*nu_l/(rhol*R0^2*omega_0);
eqparam.delta_shell  = 4*Ks/(rhol*R0^3*omega_0);

% Analogously, compute damping constant for thermal damping:
eqparam.delta_th  = 4*eqparam.nu_th/(rhol*R0^2*omega_0);

% Modification of the radiation damping constant (follows from
% linearisation of the Rayleigh-Plesset equation). Is the same as in Van
% der Meer et al., if no surface tension.
eqparam.delta_rad = 1/(rhol*R0*omega_0)*...
    (P0 + 2*sig_0/R0)*3*eqparam.kappa/c;

% Compute the sum of the damping constants:
eqparam.delta     = eqparam.delta_rad + eqparam.delta_th + ...
    eqparam.delta_vis + eqparam.delta_shell;
    
end