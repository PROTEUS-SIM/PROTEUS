function d_in = das_transmit_distance(X, Y, transducer, transmit)
%DAS_TRANSMIT_DISTANCE Transmit path length of the delay-and-sum model.
%
% d_in = DAS_TRANSMIT_DISTANCE(X, Y, transducer, transmit) returns, for
% each point (X, Y) (axial, lateral: PROTEUS convention) [m], the distance
% travelled by the transmitted wave from the moment the first element
% fires (t = 0, the smallest transmit delay) until the wave reaches the
% point. d_in has the size of X.
%
% transducer: struct with fields
% - x_el, y_el:  axial and lateral element positions [m]
% - center:      axial coordinate of the centre of curvature (-Inf for a
%                linear array) [m]
% transmit: struct with fields
% - focus:  focal distance [m]: > 0 focused, < 0 diverging (virtual
%           source behind the array), Inf: plane wave for a linear array,
%           diverging wave from the centre of curvature for a curved array
% - steer:  steering angle [rad], positive towards positive lateral
%           coordinates
%
% The model matches the PROTEUS transmit delays (compute_delays): for each
% element, d_in at its own position equals c times its delay. As in
% compute_delays, t = 0 is the smallest delay over all elements, whether
% they fire (apodization) or not.

x_el = transducer.x_el(:)';
y_el = transducer.y_el(:)';

F     = transmit.focus;
steer = transmit.steer;

if ~isfinite(F) && isfinite(transducer.center)
    % Curved array: diverging wave from the centre of curvature
    F = transducer.center;
end

if isfinite(F)
    % Focal point or virtual source:
    Fx = F*cos(steer);  % axial
    Fy = F*sin(steer);  % lateral
    D_el = sqrt((y_el-Fy).^2 + (x_el-Fx).^2);
    D    = sqrt((Y-Fy).^2 + (X-Fx).^2);

    if F < 0
        % Diverging wave, t = 0 at the element closest to the virtual
        % source:
        d_in = D - min(D_el);
    else
        % Converging wave, t = 0 at the element farthest from the
        % focus. Points before the focus (s = 1) are reached earlier than
        % the focus, points after it (s = -1) later:
        s = sign((Fy-Y)*sin(steer) + (Fx-X)*cos(steer));
        d_in = max(D_el) - s.*D;
    end
else
    % Plane wave, t = 0 at the first element along the propagation
    % direction:
    d_in = Y*sin(steer) + X*cos(steer) - ...
        min(y_el*sin(steer) + x_el*cos(steer));
end

end
