function show_microbubble_positions(save_path, Geometry, PATHS)
% Show the microbubble positions of the microbubble frames stored in
% save_path.

filelist = dir([save_path filesep 'Frame_*.mat']);

% Maximum number of frames to show in the plot:
N_frames_max = 5000;
if N_frames_max < length(filelist)
    title_info = [num2str(N_frames_max) ' randomly selected frames'];
else
    title_info = 'all frames';
    N_frames_max = length(filelist);
end

I = randperm(length(filelist),N_frames_max);
filelist = filelist(I);

load([save_path filesep 'FlowSimulationParameters.mat'],...
    'FlowSimulationParameters')

N_MB = FlowSimulationParameters.NMicrobubbles;

X = zeros(N_MB,N_frames_max);
Y = zeros(N_MB,N_frames_max);
Z = zeros(N_MB,N_frames_max);

waitbar_msg = ['Retrieving microbubble positions (' title_info ')'];
w = waitbar(0,waitbar_msg);

for n = 1:N_frames_max
    
    waitbar((n-1)/N_frames_max,w,waitbar_msg)
    drawnow

    load([filelist(n).folder filesep filelist(n).name],'Frame')
    
    X(:,n) = Frame.Pulse1.Points(:,1);
    Y(:,n) = Frame.Pulse1.Points(:,2);
    Z(:,n) = Frame.Pulse1.Points(:,3); 

end

close(w)

fig = figure();
ax  = axes(fig);

plot3(ax,X(:)*1e3,Y(:)*1e3,Z(:)*1e3,'wo');
hold(ax, 'on')

% Load the vertices of the STL file:
STLfilepath = fullfile(PATHS.GeometriesPath, ...
                         Geometry.Folder, ...
                         Geometry.STLfile);

[X,Y,Z] = stlread_gui(STLfilepath,PATHS.VoxelisationPath);

% Convert the STL vertex coordinates to meters:
X = X*Geometry.STLunit;
Y = Y*Geometry.STLunit;
Z = Z*Geometry.STLunit;

fraction = Geometry.Visualization.Fraction;
[X,Y,Z] = sparsify(X,Y,Z,fraction);

% Plot the vessel mesh vertices:
plot3(ax,X*1e3,Y*1e3,Z*1e3,'r.','MarkerSize',0.5)

xlabel(ax, 'x (mm)')
ylabel(ax, 'y (mm)')
zlabel(ax, 'z (mm)')
title(ax,  ['Microbubble positions (' title_info ')'],'Color','w')

set(ax,  'Color','k', 'XColor','w', 'YColor','w','ZColor','w')
set(fig, 'Color','k')

legend(ax, 'Microbubbles')
ax.Legend.EdgeColor = [0 0 0];
ax.Legend.TextColor = [1 1 1];
ax.Legend.Location  = 'northeast';

ax.DataAspectRatio = [1 1 1];

end