function source = update_source(...
    source, mass_source, source_weights, source_mask_idx_new, Grid, medium)
% Multiply the spatial delta function with the mass source signals of 
% point source, convert to pressure signals and add to the source
% struct.
%
% See equation 2.19 in the k-Wave manual (Manual Version 1.1, August 
% 27, 2016) for the relation between mass sources and pressure sources.
% The pressure sources are converted back to mass sources in the k-Wave
% code kspaceFirstOrder_scaleSourceTerms.m

% k-Wave cannot handle source masks with all values zero:
if isempty(source_mask_idx_new)
    return
end

% Get source mask and source data of the original source:
if isfield(source,'p_mask')
    p_old  = source.p;
else
    source.p_mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz);
    p_old  = [];
end

% Convert mass source to mass source density.
% (From the k-Wave manual: S_M is a mass source term and represents the 
% time rate of the input of mass per unit volume in units of kg m^?3 s^-1)
mass_source = double(mass_source/(Grid.dx*Grid.dy*Grid.dz));

% Speed of sound at the source points:
c0 = medium.sound_speed(source_mask_idx_new);

p_new = (source_weights * mass_source) .* (c0*Grid.dx/2);
p_new = cast(full(p_new),class(mass_source));

% Add new source points to the source mask:
source_mask_idx_old = find(source.p_mask);
source.p_mask(source_mask_idx_new) = 1;
source_mask_idx_full = find(source.p_mask);

% Initialize output source data:
N = length(source_mask_idx_full);
Nt1 = size(p_old,2);
Nt2 = size(p_new,2);
source.p = zeros(N,max(Nt1,Nt2));

% Add new source data to the original source data:
[~,j_old] = ismember(source_mask_idx_old,source_mask_idx_full);
[~,j_new] = ismember(source_mask_idx_new,source_mask_idx_full);

source.p(j_old,1:Nt1) = p_old;
source.p(j_new,1:Nt2) = source.p(j_new,1:Nt2) + p_new;

end