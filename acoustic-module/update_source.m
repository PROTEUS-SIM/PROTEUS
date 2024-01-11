function source = update_source(...
    source, mass_source, source_weights, source_mask_idx, Grid, medium)
% Multiply the spatial delta function with the mass source signals of 
% point source, convert to pressure signals and add to the source
% struct.
%
% See equation 2.19 in the k-Wave manual (Manual Version 1.1, August 
% 27, 2016) for the relation between mass sources and pressure sources.
% The pressure sources are converted back to mass sources in the k-Wave
% code kspaceFirstOrder_scaleSourceTerms.m

% k-Wave cannot handle source masks with all values zero:
if isempty(source_mask_idx)
    return
end

source.p_mask = zeros(Grid.Nx, Grid.Ny, Grid.Nz);
source.p_mask(source_mask_idx) = 1;

% Convert mass source to mass source density.
% (From the k-Wave manual: S_M is a mass source term and represents the 
% time rate of the input of mass per unit volume in units of kg m^?3 s^-1)
mass_source = double(mass_source/(Grid.dx*Grid.dy*Grid.dz));

% Speed of sound at the source points:
c0 = medium.sound_speed(source_mask_idx);

source.p = (source_weights * mass_source) .* (c0*Grid.dx/2);
source.p = cast(full(source.p),class(mass_source));

end