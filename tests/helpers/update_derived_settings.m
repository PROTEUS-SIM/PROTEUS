function S = update_derived_settings(S)
%UPDATE_DERIVED_SETTINGS Recompute the settings derived from the others.
%
% Equivalent of MainGUI.updateParameters: recomputes the simulation domain
% and the sampling rate after the settings in S were modified.

S.Geometry.Domain.Margin = 2*S.Medium.SpeedOfSound/S.Transmit.CenterFrequency;
S.Geometry = compute_simulation_domain(S.Geometry, S.Transducer, S.Transmit);
S.SimulationParameters = update_simulation_parameters( ...
    S.SimulationParameters, S.Medium, S.Transmit.CenterFrequency);
end
