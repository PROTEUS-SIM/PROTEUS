function estim_time_mem(Grid, source, param, beta_coeff_file)

Nx = Grid.full_size(1);
Ny = Grid.full_size(2);
Nz = Grid.full_size(3);

grid_size = Nx * Ny * Nz;
load(beta_coeff_file, 'beta_coeff');
t_step = 10^(beta_coeff(1) + beta_coeff(2) * log10(grid_size));

for i = 1 : 3
    dt = param.CFL * Grid.dx / param.c_max;
    num_steps(i) = floor(param.tr(i) / dt) + 1;   
    time_sim(i) = t_step * num_steps(i);
end

time_sim_all = time_sim(1) + param.num_frames * (time_sim(2) * param.num_int + time_sim(3));        
time_sim_all = time_sim_all * param.num_pulse;
%% 
% highest memory consumption is expected in 3rd itteration
A_max = 9;
B_max = 2;

input = numel(source.ux) + param.max_mb * num_steps(2);

output = size(source.ux, 1);

mem_sim.min = (13 * Nx * Ny * Nz + 7 * Nx /2 * Ny * Nz) * 4 / 1024^3  + ...
    (input * 8  + output * 8) / 1024^3;

mem_sim.max = ((13 + A_max) * Nx * Ny * Nz + (7 + B_max) * Nx /2 * Ny * Nz) * 4 / 1024^3  + ...
    (input * 8 + output * 8) / 1024^3;
%% output
disp(['Minimum required memory = ', num2str(mem_sim.min), ' Gb', ' max = ', num2str(mem_sim.max), ' Gb']);
disp(['Required time = ', num2str(time_sim_all), ' s']);
end
