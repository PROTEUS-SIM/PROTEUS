function write_settings(S, P, file)
%WRITE_SETTINGS Write the settings struct S to a PROTEUS settings file.
write_to_file(S.Microbubble, S.SimulationParameters, S.Geometry, ...
    S.Transducer, S.Acquisition, S.Medium, S.Transmit, P, file);
end
