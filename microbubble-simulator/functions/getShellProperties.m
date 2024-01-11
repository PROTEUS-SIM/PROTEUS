function shell = getShellProperties(bubble,shell,liquid)
% Shell properties of a microbubble. According to:
% Marmottant et al., J. Acoust. Soc. Am. 118 6, 2005
% OR
% Segers et al, Soft Matter, 14, 2018
%
% For the Segers model, the surface tension curve can be expressed as a
% polynomial fit (Segers) or as a lookup table (SegersTable).


%% MODEL CHECK AND MAXIMUM SURFACE TENSION

if bubble.R0<1e-6 || bubble.R0>4e-6
    warning('Shell viscosity uncertain for given microbubble radius.')
end

if strcmp(shell.model,'Marmottant')
    shell.sig_l = liquid.sig; 	% Maximum surface tension (N/m)
    
elseif strcmp(shell.model,'Segers')||strcmp(shell.model,'SegersTable')
    % Shell properties, following: 
    % Segers et al., Soft Matter, 2018, 14, 9550-9561

    shell.sig_l = 0.072;      	% Maximum surface tension (water) (N/m)
    if shell.sig_l~= liquid.sig
        error('Segers shell model only valid in water.')
    end
    
else
    error('Shell model not recognized.')
end

%% SHELL VISCOSITY
% Shell viscosity, Segers et al, Soft Matter, 14, 2018
% Surface dilatational viscosity (N.s/m). Fit to figure 6B:
c_1=1.5e-9; 
c_2=8e5; 
shell.Ks = c_1.*exp(c_2.*bubble.R0); 


%% MARMOTTANT MODEL
if strcmp(shell.model,'Marmottant')
    % Linearised surface tension curve (Marmottant et al., J. Acoust. Soc.
    % Am. 118 6, December 2005)
    
    shell.chi   = 0.55;         % Shell stiffness (N/m) (Marmottant value)
    
    % Compute the buckling radius (m):
    shell.Rb    = bubble.R0/sqrt(1+shell.sig_0/shell.chi);
end


%% EXPERIMENTAL SURFACE TENSION CURVES (POLYNOMIAL FIT)

if strcmp(shell.model,'Segers')
    
    % Load the fit to the experimental surface tension curves. These are 
    % the fit coefficients from the polynomial fit from Segers et al, Soft 
    % Matter, 14, 2018. The fit coefficients printed in the article do not 
    % have sufficient precision to reproduce the curve. Below are the 
    % double-precision values obtained from Tim Segers.
    
    fit = load('fit_SigmaR_04-08-2017.mat');

    A_0 = 4*pi*bubble.R0^2;         % Initial microbubble area

    % Get the domain boundaries of the fit:
    [A_m1,A_m2] =  find_domain_boundaries(fit.fit.coeff);

    shell.coeff = fit.fit.coeff;    % Fit coefficients.
    shell.A_m1 = A_m1;              % Left domain boundary fit.
    shell.A_m2 = A_m2;              % Right domain boundary fit.
    
   	% Find the normalized area for which the fit equals sig_0:
    A_m0 = find_A_m0(shell);
    
    shell.A_N  = A_0/A_m0;          % Reference area surface tension curve.
    
end

%% EXPERIMENTAL SURFACE TENSION CURVES (TABLE LOOKUP)

if strcmp(shell.model,'SegersTable')
    
    % Load the fit to the experimental surface tension curves. The fit has
    % already been evaluated for a predifined array A_m of normalised 
    % surface areas. The fit was evaluated with makeSegersArray.m.
    
    fit = load('fit_SigmaR_evaluated.mat');
    
    A_0 = 4*pi*bubble.R0^2;         % Initial microbubble area
    
    shell.A_m1 = min(fit.A_m);    	% Left domain boundary fit.
    shell.A_m2 = max(fit.A_m);    	% Right domain boundary fit.
    
    % Find the normalized area for which the fit equals sig_0:
 	A_m0 = interp1(fit.sig, fit.A_m, shell.sig_0);
    
    shell.A_N  = A_0/A_m0;          % Reference area surface tension curve.
    
    % Surface tension curve as an interpolant:
    shell.sig = griddedInterpolant(fit.A_m,fit.sig);
    
end

end