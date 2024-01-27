function write_video(IMG,z,x,videoFileName)
%WRITE_VIDEO reads a stack of ultrasound images, displays them, and records
%a video.

Nframes = size(IMG,3);

v = VideoWriter(videoFileName, 'MPEG-4' );
open(v)

dbrange = 45;  % Dynamics range in dB
Nticks  = 10;  % Number of ticks for the figure colorbar
scale   = 1.5; % Scale for the figures

% Figure axis limits
RI = imref2d(size(IMG,[1 2]));
RI.XWorldLimits = [min(z*1e3) max(z*1e3)];
RI.YWorldLimits = [min(x*1e3) max(x*1e3)];

fig = figure();
ax = gca;

for iframe = 1:Nframes
    
    % Current frame:
    img = IMG(:,:,iframe);

    % Conversion to 16 bit integers:
    img = uint16((img+dbrange)/dbrange.*2^16);
   
    imshow(img,RI,'InitialMagnification',round(scale*100),'Parent',ax);
    colormap('gray')
    h = colorbar;
    h.Ticks = linspace(0,2^16,Nticks);
    h.TickLabels = linspace(-dbrange,0,Nticks);

    xlabel('Axial distance (mm)',   'interpreter','latex','fontsize',14)
    ylabel('Lateral distance (mm)', 'interpreter','latex','fontsize',14)
    ylabel(h,'Image intensity (dB)','interpreter','latex','fontsize',14);
    title(['Frame ' num2str(iframe) ' out of ' num2str(Nframes)])
    drawnow

    writeVideo(v,getframe(fig));

end

close(v);

end