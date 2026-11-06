function Transducer = get_transducer_integration_points(Transducer, Grid)

if isfield(Transducer,'Configuration') && ...
        strcmp(Transducer.Configuration,'RCA')
    % Row-column array
    
    % The first half of the transducer elements represent the columns:
    N = Transducer.NumberOfElements;
    if mod(N,2)
        error('Number of elements in RCA must be even.')
    else
        Transducer.NumberOfElements = N/2;
    end
    
    % User linear transducer definition to obtain column elements:
    Transducer = get_columns(Transducer, Grid);
    
    % Exchange lateral and elevation coordinates to turns columns into
    % rows:
    columns = Transducer.integration_points;
    rows    = columns(:,:,[1 3 2]);
    
    Transducer.NumberOfElements = N;

    % Append columns with rows:
    Transducer.integration_points = [columns; rows];

    apod1 = Transducer.integration_transmit_apodization;
    apod2 = Transducer.integration_receive_apodization;

    Transducer.integration_transmit_apodization = repmat(apod1,2,1);
    Transducer.integration_receive_apodization  = repmat(apod2,2,1);

elseif isfield(Transducer,'Configuration') && ...
        strcmp(Transducer.Configuration,'Custom')
    
    % Custom points must follow the PROTEUS orientation (x axial, y
    % lateral, z elevation): an aperture extending mostly along x suggests
    % another orientation (e.g. z as depth).
    P = reshape(Transducer.integration_points, [], 3);
    span = max(P,[],1) - min(P,[],1);
    if span(1) > max(span(2:3))
        warning('get_transducer_integration_points:orientation', ...
            ['The custom transducer extends %.1f mm along x (axial) but ' ...
            'only %.1f mm along y and %.1f mm along z. PROTEUS uses x ' ...
            'axial, y lateral, z elevation: check the orientation of ' ...
            'the integration points.'], span(1)*1e3, span(2)*1e3, span(3)*1e3)
    end

    % Quadrature weight for each integration point:
    Transducer.integration_weights = ...
        Transducer.integration_area/(Grid.dy*Grid.dz);
    
    % Transmit apodization and receive apodization:
    apodization = ones(size(Transducer.integration_points,[1,2]));
    if ~isfield(Transducer,'integration_transmit_apodization')
        Transducer.integration_transmit_apodization = apodization;
    end
    if ~isfield(Transducer,'integration_receive_apodization')
        Transducer.integration_receive_apodization  = apodization;
    end
    
else
    % Linear array
    Transducer = get_columns(Transducer, Grid);
end

end

function Transducer = get_columns(Transducer,Grid)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PHYSICAL PROPERTIES OF THE TRANSDUCER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

N = Transducer.NumberOfElements;
p = Transducer.Pitch;
w = Transducer.ElementWidth;

% A curved array is kerf-free: each element spans one pitch along the arc
% (see get_element_geometry):
curved = isfield(Transducer,'Configuration') && ...
    strcmp(Transducer.Configuration,'Curved');
if curved
    El = get_element_geometry(Transducer);
    w = El.width;
end

W = (N-1)*p + w;                % Transducer width
H = Transducer.ElementHeight;   % Transducer height

y_min = -W/2 + (0:(N-1))*p;     % Left boundaries of transducer elements

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROPERTIES OF THE INTEGRATION POINT DISTRIBUTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Target integration point density (one-dimensional):
target_density = Transducer.IntegrationDensity;

% Number of integration points per element in lateral direction (along the
% arc for a curved array):
N_int_y = ceil(target_density*w/Grid.dy);

% Integration point spacing in lateral direction:
spacing_int_y = w/N_int_y;

% Integration point spacing in elevation direction:
spacing_int_z = Grid.dz/target_density;

% Set up integer grid in elevation direction. The integer grid makes sure
% that the integration points overlap with the grid in the integration
% direction in case the integration point density is 1, which speeds up
% integration.
Z1 = ceil(-H/2/spacing_int_z);
Z2 = floor(H/2/spacing_int_z);

% Number of integration points per element in the elevation direction:
N_int_z = length(Z1:Z2);

% Total number of integration points per element:
N_int = N_int_y*N_int_z;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET THE INTEGRATION POINTS FOR EACH ELEMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Matrix for holding the transducer integration points:
Transducer.integration_points = zeros(N,N_int,3);

for i = 1:N
    % Coordinates of the integration points in the current element:
    if curved
        % Uniform spacing along the arc, centred on the element:
        s = ((1:N_int_y) - (N_int_y+1)/2)*spacing_int_y;
        phi = El.theta(i) + s/El.Radius;
        x = El.Center + El.Radius*cos(phi);
        y = El.Radius*sin(phi);
        z = (Z1:Z2)*spacing_int_z;

        [x,z] = ndgrid(x,z);
        y = repmat(y',1,N_int_z);
        Transducer.integration_points(i,:,:) = [x(:) y(:) z(:)];
        continue
    end

    x = 0;
    y = y_min(i) + (1:N_int_y)*spacing_int_y - spacing_int_y/2;
    z = (Z1:Z2)*spacing_int_z;
    
    [x,y,z] = ndgrid(x,y,z);
    Transducer.integration_points(i,:,:) = [x(:) y(:) z(:)]; 
    
end

% Quadrature weight for each integration point (for a curved array, the
% points are equally spaced along the arc, so the weight is the same):
Transducer.integration_weights = ...
    spacing_int_y*spacing_int_z/(Grid.dy*Grid.dz);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% APODIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

apodization_Z = false;
if apodization_Z == true

    % Apodization window in elevation direction (0 Rectangular window,
    % 1 Hann window):
    apod_winZ   = getWin(N_int_z, 'Tukey', 'Param', 0.5, 'Plot', false); 
    apod_winZ   = repmat(transpose(apod_winZ),N_int_y,1);
    apodization = repmat(transpose(apod_winZ(:)),N,1);
else
    apodization = ones(N,N_int);
end

% Transmit apodization and receive apodization:
Transducer.integration_transmit_apodization = apodization;
Transducer.integration_receive_apodization  = apodization;

end

