function [response, eqparam] = calcBubbleResponse(liquid, gas, ...
    shell, bubble, pulse)
% Compute the radial response and the scattered pressure of a microbubble.
% Nathan Blanken, University of Twente, 2023

N_MB = length(bubble); % Number of microbubbles

%% Timer 
time_out = N_MB*60; % Stop integration after time_out seconds
assignin('base','timeout_reached',0);   % Time-out status
timer_inst = timer('TimerFcn', ...
    'timeout_reached = 1; disp("timeout reached")',...
    'StartDelay', time_out);

%% Display progress settings

% Show ODE solver progress or not: 
dispProgress = pulse.dispProgress;

assignin('base','tplo',0)       % Time to display progress (s)
assignin('base','dtplo',5e-7)   % Increment time to display progress (s)

%% Equation parameters (damping parameters and polytropic exponent)
for i = N_MB:-1:1 % descending for memory allocation
    eqparam(i) = getEqParam(liquid, gas, shell(i), bubble(i), pulse);
end

%% Initial conditions and nondimensionalization
x0dot = 0; x0 = 0;                              % Initial conditions
x0v = repmat([x0; x0dot],[N_MB,1]);

T = sqrt(liquid.rho.*[bubble.R0].^2/liquid.P0); % Characteristic time scale
T = median(T);
tau = pulse.tq/T;                               % Nondimensional query time

%% Interpolant for the acoustic pressure
for i = N_MB:-1:1
    P_acc(i).p = griddedInterpolant(pulse.t, pulse.p(i,:),'pchip');
end

%% ODE options
InitialSte = 1e-12;
options = odeset('BDF','on','AbsTol',1e-6,'RelTol',1e-6, ...
    'InitialStep',InitialSte,...
    'OutputFcn',@(tau,y,flag) odeOutputFcn(tau,y,flag,T,dispProgress));

%% Run the ODE solver:
RP_handle = @(tau,vec) simple_RP(tau,vec,...
    liquid,shell,eqparam,bubble, P_acc, T);

start(timer_inst)
[tau,X]=ode45(RP_handle,tau,x0v,options);
stop(timer_inst)

X = reshape(X,[],2,N_MB);

%% Return to dimensional variables
for i = N_MB:-1:1
    response(i).R = bubble(i).R0.*(1+X(:,1,i));   % Radius (m)
    response(i).Rdot = bubble(i).R0.*X(:,2,i)/T;  % Radial velocity (m/s)
    response(i).t = tau*T;
end
    
%% Remove progress variables
evalin( 'base', 'clear timeout_reached')
evalin( 'base', 'clear tplo')
evalin( 'base', 'clear dtplo')

end