function T = reference_transducer(T)
%REFERENCE_TRANSDUCER Transducer struct as in the reference code.
%
% T = REFERENCE_TRANSDUCER(T) removes the fields added after the reference
% code (6a863b4) and replaces calibrated impulse responses by the estimate
% from the bandwidth, so that the regression cases compare the same
% quantities as the baselines. Settings without the new fields (as
% written by older versions) must also still run, which the end-to-end
% cases check.

T = rmfield(T, intersect(fieldnames(T), {'calibrated','Radius'}));
if ~strcmp(T.ImpulseResponseType,'Estimate')
    T.ImpulseResponseType = 'Estimate';
    T.SamplingRate        = 250e6;    % [Hz]
    T = estimate_impulse_response(T);
end
end
