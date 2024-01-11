function sig = calc_surface_tension(R,shell)
% Compute the shell surface tension for a bubble radius R.

if strcmp(shell.model,'Marmottant')
	% surface tension of a bubble shell
    % according to Marmottant et al, JASA, 18, 2005
    
    chi   = shell.chi;      % Surface dilatational viscosity (N.s/m)
    sig_l = shell.sig_l;    % Surface tension of surrounding liquid (N/m)
    Rb    = shell.Rb;       % Buckling radius (m)

    sig = chi*(R.^2/Rb^2 - 1);      % Marmottant model

    sig(sig<0) = 0;                 % buckling
    sig(sig>sig_l) = sig_l;         % surface tension of surrounding liquid
    
elseif strcmp(shell.model,'Segers')
    % Experimental surface tension curve from Segers et al., Soft Matter, 
    % 2018, 14, 9550-9561. Compute with evaluation of polynomial fit.

    A_m = 4*pi*R.^2/shell.A_N;      % Normalised surface area

    A_m1 = shell.A_m1;
    A_m2 = shell.A_m2;

    sig = polyval(shell.coeff,A_m);
    
    sig(A_m<A_m1) = 0;              % buckling
    sig(A_m>A_m2) = shell.sig_l;    % surface tension of surrounding liquid
    
elseif strcmp(shell.model,'SegersTable')
	% Experimental surface tension curve from Segers et al., Soft Matter, 
    % 2018, 14, 9550-9561. 
    
    A_m = 4*pi*R.^2/shell.A_N;      % Normalised surface area
    
    A_m1 = shell.A_m1;
    A_m2 = shell.A_m2;
    
    sig = A_m*0;                    % buckling
    sig(A_m>A_m2) = shell.sig_l;    % surface tension of surrounding liquid
    
    % For the elastic regime, compute surface tension through
    % interpolation:
    sig(A_m>A_m1 & A_m<A_m2) = shell.sig(A_m(A_m>A_m1 & A_m<A_m2));
    
end

end