function  pressure_new = resample_signal(pressure_old, fs_old, fs_new, disp_fig)

t_old = [0:length(pressure_old)-1] / fs_old;
t_new = [0:floor(t_old(end)*fs_new)] / fs_new; 
[Ts,T] = ndgrid(t_new, t_old);

x = (Ts - T) * fs_old;
i=find(x==0);                                                              
x(i)= 1;                     
y = sin(pi*x)./(pi*x);                                                     
y(i) = 1;   

if isrow(pressure_old)
    pressure_old = pressure_old';
end
pressure_new = y * pressure_old;
pressure_new = pressure_new';

if disp_fig
    figure()
    plot(t_old, pressure_old, 'o', t_new, pressure_new)
    xlabel Time, ylabel Signal
    legend('Sampled','Interpolated','Location','SouthWest')
    legend boxoff
    
    N = length(pressure_old);
    f_old = (0:N-1)/N*fs_old;   % frequency array
    pfft_old = abs(fft(pressure_old))/N;

    N = length(pressure_new);
    f_new = (0:N-1)/N*fs_new;   % frequency array    
    pfft_new = abs(fft(pressure_new))/N;

    figure()
    plot(f_old, pfft_old); hold on;
    plot(f_new, pfft_new); 

end
end