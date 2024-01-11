function A_m0 = find_A_m0(shell)
% Find the normalized area A_m = A/A_N for which sig = sig_0.


coeff = shell.coeff;    % Fit coefficients
A_m1  = shell.A_m1;     % Left domain boundary fit.
A_m2  = shell.A_m2;     % Right domain boundary fit.
sig_0 = shell.sig_0;    % Initial surface tension

% Shift the curve downwards by sig_0:
coeff(end) = coeff(end)-sig_0;

% Find the roots of the vertically shifted curve:
R = roots(coeff);

% Exclude imaginary roots from search:
R = R(imag(R)==0);

% Only keep the solution within the domain of the fit:
A_m0 = R(R>A_m1&R<A_m2);

% Check if the number of solutions is 1:
if length(A_m0) > 1
    error('Multiple solutions found.')
end

end