function beta_coeff = time_calibration()
T = readtable('time_estimation/kWave_curve.csv');
grid_sizes = T.Var1;
time_steps = T.Var2;

figure()
scatter(grid_sizes, time_steps)
set(gca,'xscale','log')
set(gca,'yscale','log')


figure()
scatter(log10(grid_sizes), log10(time_steps))

grid_sizes_log_matrix = [ones(length(grid_sizes),1) log10(grid_sizes)];
b = grid_sizes_log_matrix\log10(time_steps);

time_steps_lr = 10.^(b(1) + b(2) * log10(grid_sizes));

figure()
scatter(grid_sizes, time_steps); hold on
scatter(grid_sizes, time_steps_lr)
set(gca,'xscale','log')
set(gca,'yscale','log')

maroilles.time_steps = [258.1/2284; 184.31/2004; 91.47/1711; 64.52/1438];
maroilles.grid_sizes = [630*480*288; 574*480*250; 512*384*216; 432*384*210];

figure()
s1 = scatter(grid_sizes, time_steps); hold on
p1 = plot(grid_sizes, time_steps_lr); hold on
s2 = scatter(maroilles.grid_sizes, maroilles.time_steps, 'k');
set(gca,'xscale','log')
set(gca,'yscale','log')
xlabel('grid size')
ylabel('time per step [s]')
legend([s1 p1 s2], {'manual', 'linear regression', 'maroilles'})

maroilles.grid_sizes_log_matrix = [ones(length(maroilles.grid_sizes),1) log10(maroilles.grid_sizes)];
maroilles.b = maroilles.grid_sizes_log_matrix\log10(maroilles.time_steps);
maroilles.time_steps_lr = 10.^(maroilles.b(1) + maroilles.b(2) * log10(grid_sizes));

figure()
s1 = scatter(grid_sizes, time_steps); hold on
p1 = plot(grid_sizes, time_steps_lr); hold on
s2 = scatter(maroilles.grid_sizes, maroilles.time_steps, 'k'); hold on
p2 = plot(grid_sizes, maroilles.time_steps_lr); 
set(gca,'xscale','log')
set(gca,'yscale','log')
xlabel('grid size')
ylabel('time per step [s]')
legend([s1 p1 s2 p2], {'manual', 'linear regression', 'maroilles', 'maroilles LR'})

beta_coeff = maroilles.b;
end

