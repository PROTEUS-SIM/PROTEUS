function b = evaluate_delta_function(x,xi,dx,N)
% Evaluate the band-limited delta function centred at xi at grid
% coordinates x. Following:
%
% Wise, E. S., Cox, B. T., Jaros, J., & Treeby, B. E. (2019). Representing 
% arbitrary acoustic source and sensor distributions in Fourier collocation
% methods. The Journal of the Acoustical Society of America, 146(1), 
% 278-288.
%
% INPUT:
% - x:  grid coordinates, d x M matrix,
% - xi: centre of delta function, d x 1 vector,
% - dX: grid spacings in each dimension, d x 1 vector
% - N:  total size of the grid in each dimension, d x 1 vector
% where d is the number of dimensions and M is the number of grid points.
%
% OUTPUT:
% - b: the band-limited delta function.

% Odd grid size (Eq. 10):
b_odd  = sin(pi*(x-xi)./dx)./(N.*sin(pi*(x-xi)./(N.*dx)));

% Even grid size (Eq. 12):
b_even = sin(pi*(x-xi)./dx)./(N.*tan(pi*(x-xi)./(N.*dx)));

% The p-th row is the one-dimensional band-limited delta functions
% along dimension p:
b = b_odd;
b(mod(N,2)==0,:) = b_even(mod(N,2)==0,:);

% Define case where x = xi (0/0):
b(x==xi) = 1;
    
% Take the product of one-dimensional band-limited delta functions (Eq.13):
b = prod(b,1);


% Additional helpful materials for calculating the sum of sines and cosines
% in the derivation of the band limited delta function:
%
% https://matthew-brett.github.io/teaching/sums_of_cosines.html
% 
% Sines and Cosines of Angles in Arithmetic Progression
% Michael P. Knapp

end