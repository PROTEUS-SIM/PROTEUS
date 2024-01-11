function plot_results(response,scatter,f,dispFig)
% Plot the radial response, the scattered pressure, and the frequency
% spectrum of the scattered pressure.

R = response.R;
t = response.t;
ts = scatter.t;
ps = scatter.ps;

if dispFig == false
    return
end

% Compute the Fourier transform of Ps(t)
fr = linspace(0,1/mean(diff(t)),length(ps));
TF = abs(fft(ps))*mean(diff(t));

% Plot the bubble radius as a function of time
figure(2);
subplot(2,2,1);
plot(t.*1e6,R.*1e6);
grid on 
xlabel('time ($\mu$s)','interpreter','latex');
ylabel('radius ($\mu$m)','interpreter','latex');
title('Radial response')

% Plot the scattered pressure as a function of time
subplot(2,2,2);
plot(ts.*1e6,ps);
grid on 
xlabel('time ($\mu$s)','interpreter','latex');
ylabel('Scattered pressure (Pa)','interpreter','latex');
title('Scattered pressure')

% Plot the Fourier transform
subplot(2,2,3);
plot(fr.*1e-6,TF);
grid on 
xlabel('frequency (MHz)','interpreter','latex');
ylabel('FFT $P_s$ (Pa.s)','interpreter','latex');
xlim([0 6*f*1e-6])
title('Fourier')
end