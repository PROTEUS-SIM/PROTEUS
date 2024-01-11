function  Vq = sinc_interpolation(X,V,Xq)
% Performs sinc interpolation to find Vq, the values of the band-limited 
% function V=F(X) at the query points Xq. 

[Ts,T] = ndgrid(Xq, X);

x = (Ts - T)/mean(diff(X));

y = sin(pi*x)./(pi*x); 
y(x==0) = 1;   

if isrow(V)
    V = V';
end

Vq = y * V;
Vq = Vq';

end