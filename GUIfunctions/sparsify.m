function [X2,Y2,Z2] = sparsify(X1,Y1,Z1,fraction)
% Make point cloud (X1,Y1,Z1) sparser with fraction frac.

% Number of points in original point cloud:
N = length(X1);

% Number of points in sparse point cloud:
N_sparse = round(N*fraction);

% Make sure number of points is at least 1 and no more than N:
if N_sparse > N
    N_sparse = N;
elseif N_sparse < 1
    N_sparse = 1;
end

% Get random indices:
I = randperm(N,N_sparse);

X2 = X1(I);
Y2 = Y1(I);
Z2 = Z1(I);

end