function [liquid, gas, bubble, shell] = ...
    compress_bubble(liquid, gas, bubble, shell, P1)
% Compute new ambient pressure, new bubble equilibrium radius, new bubble
% equilibrium surface tension, and new gas density (at new ambient 
% pressure) after application of overpressure P1 (Pa). Negative P1 
% corresponds to underpressure.
%
% Nathan Blanken, University of Twente, 2021

kappa = 1;                  % Polytropic exponent (isothermal)

R0 = bubble.R0;             % Original bubble equilibrium radius
P0 =    liquid.P0;          % Original ambient pressure (Pa)
sig_0 = shell.sig_0;        % Original equilibrium surface tension

N = 1e4;
R = R0*linspace(0.5,2,N);	% Search array radius (m)

sig = calc_surface_tension(R,shell);

P_in = (P0 + 2*sig_0/R0)*(R/R0).^(-3*kappa);    % Pressure inside bubble
P_eq = P0 + 2*sig./R + P1;                      % Equilibrium pressure

% Find radius R_new for which P_in = P_eq
R_new = find_intersections(P_in,P_eq,R);   

% Check the number of solutions:
if isempty(R_new)
    error('Overpressure too low or too high to find solution.')
elseif length(R_new) > 1
    warning(['Multiple solution found. Selecting new value of R0 '...
        'closest to old value of R0.'])
    [~,I] = min(abs(R_new - R0));
    R_new = R_new(I);    
end

% New equilibrium surface tension:
sig_new = calc_surface_tension(R_new,shell);

% Isothermal compression of the gas:
rho_new = gas.rho*(P0 + P1)/P0;

liquid.P0   = P0 + P1;   	% New ambient pressure (Pa)
bubble.R0   = R_new;      	% New equilibrium bubble radius (m)
shell.sig_0 = sig_new;      % New equilibrium surface tension (N/m)
gas.rho     = rho_new;      % New gas density (outside bubble) (kg/m^3)

end

function x_solve = find_intersections(y2,y1,x)
% Find values of x for which y2=y1.

% Find changes in the sign of the difference of the two functions:
I = find(boolean(diff(sign(y2-y1))));

% Linearly interpolate to find crossing points:
x_solve = zeros(1,length(I));
for k = 1:length(I)
    m = I(k);
    x_solve(k) = interp1(y2(m:m+1) - y1(m:m+1),x(m:m+1),0);
end

% Remove duplicates from solutions:
x_solve = unique(x_solve);

end
