function [dvec] = simple_RP(tau, vec, ...
    liquid,shell,eqparam,bubble, P_acc, T)
% Rayleigh-Plesset model according to:
% Marmottant et al, J. Acoust. Soc. Am, 118, 2005. (Eq. 3)
% 
% Nathan Blanken, University of Twente, 2023
% Modifications by Guillaume Lajoinie, 2023

% Microbubble and shell properties
R0    = [bubble.R0];     % Initial microbubble radii (m)
Ks    = [shell.Ks];      % Shell stiffness (N/m)
sig_0 = [shell.sig_0];   % Initial surface tensions (N/m)

% Liquid properties
rhol =  liquid.rho;      % Density (kg/m^3)
P0   =  liquid.P0;       % Ambient pressure (Pa)
c    =  liquid.c;        % speed of sound (m/s)

kappa = [eqparam.kappa]; % Polytropic exponents
nu    = [eqparam.nu];    % Effective viscosities (Pa.s)

% Convert nondimensional time to dimensional time:
t = tau*T;

N_MB = length(bubble);
vec  = reshape(vec,[2, N_MB]);

x = vec(1,:);
xdot = vec(2,:);

% Get surface tension for these bubble radii:
R = R0.*(1+x);

% Compute the surface tension of the shell at radii R:
for i = N_MB:-1:1
    sig(i) = calc_surface_tension(R(i),shell(i));
end

% Evaluate the pressure interpolant at the queried time:
P = zeros(1,N_MB);
for i = 1:N_MB
    P(i) = P_acc(i).p(t);
end

% Nondimensional RP equation:
xdotdot = 1./(1+x).*(...
    -3/2.*xdot.^2 ...
    + P0/rhol./R0.^2*T^2.*...
    (...
    (1 + 2*sig_0./(R0*P0)).*(1+x).^(-3*kappa).*...
    (1-3*kappa/c/T.*R0.*xdot)...
    - 1 - 2*sig./(R0.*P0).*(1+x).^(-1) ...
    - 4*nu/P0/T.*xdot./(1+x) ...
    - 4*Ks/P0./R0/T.*xdot./(1+x).^2 ...
    - P/P0 ...
    )...
    );

dvec(1,:) = vec(2,:);
dvec(2,:) = xdotdot;

dvec = reshape(dvec,[2*N_MB, 1]);

end