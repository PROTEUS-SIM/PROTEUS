function [A_m,sig] = compute_surface_tension(Microbubble,Medium)

Liquid = Medium.Vessel;

% If no file was selected, output empty arrays:
if strcmp(Microbubble.Shell.Model,'Custom') && ...
        isempty(Microbubble.Shell.FitFile)
    
    % If no file was selected, output empty arrays.
    A_m = [];
    sig = [];
    return

end

switch Microbubble.Shell.Model
    case 'Marmottant'
    % surface tension of a bubble shell
    % according to Marmottant et al, JASA, 18, 2005

        chi   = Microbubble.Shell.Elasticity;       
        sig_0 = Microbubble.Shell.InitialSurfaceTension;

        % Surface tension of surrounding liquid [N/m]
        sig_l = Liquid.SurfaceTension; 	

        A_m = linspace(0.8,1.2,500);    % Normalized area
        A_mb    = 1/(1+sig_0/chi);      % Normalized buckling area

        sig = chi*(A_m/A_mb - 1);       % Marmottant model

        sig(sig<0) = 0;                 % buckling
        sig(sig>sig_l) = sig_l;         % surface tension of surrounding 
                                        % liquid

    case{'Segers','Custom'}

        % Initial surface tension
        sig_0   = Microbubble.Shell.InitialSurfaceTension;

        fit.sig = Microbubble.Shell.SurfaceTension;
        fit.A_m = Microbubble.Shell.NormalizedArea;

        % Surface tension of surrounding liquid [N/m]
        sig_l = max(fit.sig);            

        A_m = linspace(0.8,1.2,500);    % Normalized area w.r.t. initial 
                                        % radius

        % Find the reference normalized area for which the fit equals 
        % sig_0:
        A_mN0 = interp1(fit.sig, fit.A_m, sig_0);

        A_mN = A_m*A_mN0;               % Normalised surface area w.r.t. 
                                        % reference radius

        A_mN1 = min(fit.A_m);           % Left boundary fit
        A_mN2 = max(fit.A_m);           % Right boundary fit

        sig = A_m*0;                    % buckling
        sig(A_mN>A_mN2) = sig_l;        % surface tension of surrounding 
                                        % liquid

        % For the elastic regime, compute surface tension through
        % interpolation:
        sig(A_mN>A_mN1 & A_mN<A_mN2) = ...
        interp1(fit.A_m, fit.sig, A_mN(A_mN>A_mN1 & A_mN<A_mN2));
    
    otherwise
        error('Unknown shell model')

end

end