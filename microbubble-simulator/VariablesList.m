%% SIMULATION INPUT
%% liquid:      liquid properties
% k:            thermal conductivity (W/m/K)
% rho:          density (kg/m^3)
% cp:           specific heat at const. p (J/kg/K)
% nu:           liquid viscosity (Pa.s)
% sig:          surface tension (N/m)
% c:            speed of sound (m/s)
% T0:           initial temperature (K)
% P0:           ambient pressure (Pa)
% Pat:          atmospheric pressure (Pa)
% a,b:          attenuation coef.: beta = a*f0^b in dB/cm, f0 in MHz
% BA:           B/A nonlinearity coefficient
% beta:         nonlinearity parameter (1 + B/A/2)
% ThermalModel  thermal model: 'Isothermal', 'Adiabatic', 'Prosperetti'

%% gas:         gas properties
% k:            thermal conductivity (W/m/K)
% rho:          density (kg/m^3)
% Mg:           molar mass (kg/mol)
% cp:           specific heat at const. p (J/kg/K)
% gam:          heat capacity ratio

%% shell:       shell properties
% model         'Marmottant', 'Segers', or 'SegersTable'
% Ks            shell viscosity (N.s/m)
% sig_0:        initial surface tension (N/m)
% chi:          shell stifness (N/m) (Marmottant model)
% Rb:           buckling radius (m) (Marmottant model)
% sig_l:        surface tension of surrounding liquid
% A_N:          reference surface area (m^2) (Segers model)

%% pulse:       drive pulse properties
% f:            centre frequency (Hz)
% w:            centre frequency (angular) (Hz)
% Nc:           number of cycles 
% A:            pressure amplitude (Pa)
% fs:           sample frequency (Hz)
% t:            time vector (s)
% p:            pressure vector (Pa)
% dp:           time derivate pressure vector (Pa/s)

%% bubble:      bubble properties of i-th bubble
% z:            distance from transducer (m)
% R0:           initial radius bubble (m)

%% COMPUTED EQUATION PARAMETERS
%% eqparam:     equation parameters 

% nu_th:        thermal damping constant (Pa.s)
% nu_rad:       radiative damping constant (Pa.s)
% nu_vis:       viscous damping constant (liquid viscosity) (Pa.s)
% nu:           total damping constant (Pa.s)
% Ks:           shell dilatational viscosity (N.s/m)
% kappa:        polytropic exponent


%% SIMULATION OUTPUT
%% response:    radial response bubble
% R:            radial response vector (m)
% Rdot:         time derivative radial response (radial velocity) (m/s)
% t:            time vector (s)

%% scatter:     scattered pressure
% ps:           scattered pressure vector (Pa)
% t:            time vector (s)

