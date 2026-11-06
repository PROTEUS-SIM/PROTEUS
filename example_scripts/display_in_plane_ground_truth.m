% DISPLAY THE IN-PLANE GROUND-TRUTH VELOCITY FIELD
%
% Displays the CFD velocity field of a flow geometry in the imaging plane
% (z = 0, the lateral-axial plane), in the simulation coordinates
% (after the geometry rotation and translation of a settings file). The
% points within 1 mm of the plane are interpolated (nearest neighbour) on
% a 0.1 mm grid covering the simulation domain.
%
% Requires the vtu.mat file of the geometry (see geometry_data/vtu2matlab.m)
% and the Image Processing Toolbox (bwboundaries).

clear; clc; close all

% Add the root directory of the repository to the MATLAB path:
addpath('..')
PATHS = path_setup();

[GUI_file, settingsFolder] = uigetfile(fullfile(PATHS.SettingsPath,'*.mat'), ...
    'Select the simulation settings file');
load(fullfile(settingsFolder, GUI_file),'Geometry')

%%

Geometry.vut_mat_file = fullfile(PATHS.GeometriesPath, ...
    Geometry.Folder, 'vtu.mat');

try
    % load the points from thr vtu.mat file
    load(Geometry.vut_mat_file,'vtuStruct'); 
    load(Geometry.vut_mat_file,'vtuProperties'); 
    
%     clear vtuStruct
catch
    folder = uigetdir(PATHS.GeometriesPath, ...
        'vtu.mat not found, please select the geometry folder');
    Geometry.vut_mat_file = fullfile(folder, 'vtu.mat');

    load(Geometry.vut_mat_file,'vtuStruct'); 
    load(Geometry.vut_mat_file,'vtuProperties'); 
    
%     clear vtuStruct
end

%%
    
pts = vtuStruct.points;
velocity = vtuStruct.cellData.velocity_phy;  
cells = vtuStruct.cells;
clear vtuStruct

%%
% flor large CDF models, keep only a description of "Npt_keep"  points
% of the vasculature; point are randomly removed to reach this
% representation to avoid the risks of distortion from regular
% subsampling.

% gridinterpolant for 1 million points takes on the order of 10s
% it takes 50 s with 5 million cells
Npt_keep = 5e6; 

disp(['reduccing data size to ' num2str(Npt_keep*1e-6) ' million cells']);

while size(cells,1)>Npt_keep
    r = randi(size(cells,1),1,2*(size(cells,1)-Npt_keep));
    cells(r' ,:) = [];
    velocity(r' ,:) = [];
end

disp('data size reduced');

%%

SI_cell = size(cells);

cells_col = cells(:);
clear cells
disp('column matrix created');

pts_cells_x = pts(cells_col,1);
pts_cells_x = reshape(pts_cells_x,SI_cell);
pts_cells_x = mean(pts_cells_x,2);
disp('x coordinates recovered');

pts_cells_y = pts(cells_col,2);
pts_cells_y = reshape(pts_cells_y,SI_cell);
pts_cells_y = mean(pts_cells_y,2);
disp('y coordinates recovered');

pts_cells_z = pts(cells_col,3);
pts_cells_z = reshape(pts_cells_z,SI_cell);
pts_cells_z = mean(pts_cells_z,2);
disp('z coordinates recovered');

pts_cells = [pts_cells_x,pts_cells_y,pts_cells_z];
clear pts_cells_x pts_cells_y pts_cells_z pts cells_col


%%

% recenter the points, based on the bounding box of the STL file
BB = Geometry.BoundingBox; 

pts_cells(:,1) = pts_cells(:,1)-BB.Center(1)./Geometry.STLunit;
pts_cells(:,2) = pts_cells(:,2)-BB.Center(2)./Geometry.STLunit;
pts_cells(:,3) = pts_cells(:,3)-BB.Center(3)./Geometry.STLunit;
disp('points_rotated');


% apply the geometry rotation to the subsampled cloud of points
pts_cells = pts_cells';
pts_cells = Geometry.Rotation*pts_cells;
pts_cells = pts_cells';

velocity = velocity';
velocity = Geometry.Rotation*velocity;
velocity = velocity';

disp('rotation applied topoints and velocity field');

pts_cells = pts_cells.*Geometry.STLunit;
velocity = velocity.*vtuProperties.velocityUnit;

%%
disp('translating to the domain center');
pts_cells(:,1) = pts_cells(:,1) + Geometry.Center(1);
pts_cells(:,2) = pts_cells(:,2) + Geometry.Center(2);
pts_cells(:,3) = pts_cells(:,3) + Geometry.Center(3);

%% removing too out-of-plane points

delt = 1e-3;
Z = pts_cells(:,3);

X = pts_cells(:,1);
Y = pts_cells(:,2);

X(abs(Z)>delt) = [];
Y(abs(Z)>delt) = [];

Vx = velocity(:,1);
Vy = velocity(:,2);

Vx(abs(Z)>delt) = [];
Vy(abs(Z)>delt) = [];


Z(abs(Z)>delt) = [];


velocity = [Vx, Vy];
pts_cells = [X, Y, Z];

%%
tic
Vx = scatteredInterpolant(pts_cells,velocity(:,1),'nearest','none' );
disp('scatterinterpolant in x created');
toc
Vy = scatteredInterpolant(pts_cells,velocity(:,2),'nearest','none' );
disp('scatterinterpolant in y created');
toc
% Vz = scatteredInterpolant(pts_cells,velocity(:,3),'nearest','none' );
% disp('scatterinterpolant in z created');
% toc

%% creating a grid aligned with the imaging plane, the (x,y) plane

disp('creating geometry');
pixel_size = 1e-4;

x_visu_v = Geometry.Domain.Xmin:pixel_size:Geometry.Domain.Xmax;
y_visu_v = Geometry.Domain.Ymin:pixel_size:Geometry.Domain.Ymax;

x_visu = repmat(x_visu_v,[length(y_visu_v) 1]);
y_visu = repmat(y_visu_v',[1 length(x_visu_v)]);

%%
% % x_visu_2 = x_visu(:);
% % x_visu_2 = reshape(x_visu_2,SI_grid);
% % figure(3)
% % imagesc(x_visu_2-x_visu);
% figure(3)
% imagesc(x_visu_v.*1e3,y_visu_v.*1e3,x_visu);
% colorbar

%% computing the velocityh on the grid using the scatterinterpolant created earlier

disp('projecting velocity field');

SI_grid = size(x_visu);

pt_grid = zeros(numel(x_visu),3);
pt_grid(:,1) = x_visu(:);
pt_grid(:,2) = y_visu(:);

Vx_visu = Vx(pt_grid);
Vy_visu = Vy(pt_grid);

Vx_visu = reshape(Vx_visu,SI_grid);
Vy_visu = reshape(Vy_visu,SI_grid);

V_mag = sqrt(Vx_visu.^2+Vy_visu.^2);


%% line test

% pt_grid_line = zeros(numel(x_visu_v),3);
% pt_grid_line(:,1) = x_visu_v;
% 
% Vx_visu_line = Vx(pt_grid_line);
% Vy_visu_line = Vy(pt_grid_line);
% 
% % Vx_visu_line = reshape(Vx_visu,SI_grid);
% % Vy_visu_line = reshape(Vy_visu,SI_grid);
% 
% V_mag_line = sqrt(Vx_visu_line.^2+Vy_visu_line.^2);
% 
% figure(2)
% plot(x_visu_v.*1e3,V_mag_line)

%% plot result 

N_keep_quiv = 50; % number of vectors to keep for the quiver plot in the long dimension.

N_skip_quiv = floor(length(x_visu_v)/N_keep_quiv);

figure(1)
subplot(2,1,1)
% Depth (x) downwards, lateral (y) horizontal, as the DAS images:
imagesc(y_visu_v.*1e3,x_visu_v.*1e3,V_mag.')
xlabel('lateral distance (mm)')
ylabel('axial distance (mm)')
axis equal
% hold all


mask = ones(size(V_mag));
mask(isnan(V_mag)) = 0;

[B,L] = bwboundaries(mask,'noholes');



subplot(2,1,2)
quiver(y_visu_v(1:N_skip_quiv:end).*1e3,x_visu_v(1:N_skip_quiv:end).*1e3,...
    Vy_visu(1:N_skip_quiv:end,1:N_skip_quiv:end).',...
    Vx_visu(1:N_skip_quiv:end,1:N_skip_quiv:end).');
hold all
for k = 1:length(B)
   boundary = B{k};
   plot(y_visu_v(boundary(:,1)).*1e3, x_visu_v(boundary(:,2)).*1e3, 'k', 'LineWidth', 1)
end
hold off
axis equal
xlim([min(y_visu_v.*1e3) max(y_visu_v.*1e3)])
ylim([min(x_visu_v.*1e3) max(x_visu_v.*1e3)])
set(gca,'ydir','reverse');
grid on
xlabel('lateral distance (mm)')
ylabel('axial distance (mm)')

% hold off
