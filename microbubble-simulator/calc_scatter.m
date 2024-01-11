function scatter = calc_scatter(response,liquid,bubble,pulse,nearfield)
% Compute the scattered pressure from a bubble.
%
% Nathan Blanken, University of Twente, 2021

t    = response.t;      % Time vector (s)
R    = response.R;      % Radial response (m)
Rdot = response.Rdot;   % Radial velocity (m/s)
rho  = liquid.rho;      % Liquid density (kg/m^3)
c    = liquid.c;        % Speed of sound in the liquid (m/s)
r    = bubble.r0;       % Distance bubble to sensor (m)

% Check if the sampling rate is sufficient for accurate computation of the
% radial acceleration:
if pulse.fs < pulse.f*20
    warning(['Insufficient sampling rate for accurate computation of '...
        'scattered pressure.'])
end

Rdotdot = zeros(size(Rdot));         % Radial acceleration (m/s^2)

% Compute radial acceleration. Take average of left derivative and right
% derivative.
Rdotdot(1:end-1) = diff(Rdot)/mean(diff(t))/2;
Rdotdot(2:end) = Rdotdot(2:end) + diff(Rdot)/mean(diff(t))/2;

% Scattered pressure according to Keller and Kolodner (1956)
if nearfield
    scatter.ps = rho*R./r.*((2*Rdot.^2 + R.*Rdotdot) ...
                - R.^3.*Rdot.^2./(2.*r^3));
else
    % If nearfield == false, neglect r^(-3) term:
    scatter.ps = rho*R./r.*((2*Rdot.^2 + R.*Rdotdot));
 
end

scatter.t = t + r/c;
end