function Pconv = smooth_distribution(P, conv_kernel_size, sigma)
%SMOOTH_DISTRIBUTION Convolve a distribution P on a 2D plane (given as a 3D
%   array with one singleton dimension) with a Gaussian convolution kernel
%   with support of size conv_kernel_size-by-conv_kernel_size and standard
%   deviation sigma. The output distribution is an array with the same size
%   as the input distribution.
%
%   Nathan Blanken, University of Twente, 2023

% Determine the singleton axis (perpendicular to the distribution plane):
normal_axis = find(size(P,1,2,3) == 1);

% Get the domain of the convolution kernel:
x_sz = (conv_kernel_size - 1)/2; Xconv = -x_sz:x_sz;
y_sz = (conv_kernel_size - 1)/2; Yconv = -y_sz:y_sz;
z_sz = (conv_kernel_size - 1)/2; Zconv = -z_sz:z_sz;

switch normal_axis
    case 1
        Xconv = 0;
    case 2
        Yconv = 0;
    case 3
        Zconv = 0;
end

[Xconv,Yconv,Zconv] = ndgrid(Xconv,Yconv,Zconv);

% Get a convolution kernel with a normal distribution:
Iconv = exp(-1/2*(Xconv.^2 + Yconv.^2 + Zconv.^2)/sigma^2);
Iconv = Iconv/sum(Iconv(:));

% Convolve the original distribution with the convolution kernel:
Pconv = convn(P,Iconv,'same');

% Normalise the new distribution:
Pconv = Pconv/sum(Pconv(:));

end