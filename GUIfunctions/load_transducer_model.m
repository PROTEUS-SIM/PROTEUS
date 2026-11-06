function Transducer = load_transducer_model(Transducer, folder)
%LOAD_TRANSDUCER_MODEL Apply the calibrated properties of a transducer.
%
% Transducer = LOAD_TRANSDUCER_MODEL(Transducer) looks for the model file
% <folder>/<Transducer.Type>.mat, where folder is the Transducer-models
% folder of the PROTEUS repository. If the file exists, its properties
% replace those in Transducer and the impulse responses are marked as
% calibrated (Transducer.ImpulseResponseType = 'Calibrated'). Otherwise
% Transducer is returned unchanged.
%
% Transducer = LOAD_TRANSDUCER_MODEL(Transducer, folder) uses another
% folder.
%
% Two file formats are accepted:
%
% 1. A variable 'Transducer' (PROTEUS format). Any of the fields
%    NumberOfElements, Pitch, ElementWidth, ElementHeight, ElevationFocus,
%    Radius, Configuration, BandwidthLow, BandwidthHigh and
%    CenterFrequency replace the catalogue values. The impulse responses
%    are TransmitImpulseResponse, ReceiveImpulseResponse and SamplingRate,
%    or IR_trans, IR_rec, Fs_trans and Fs_rec (the two sampling rates
%    must be equal). Other fields (for example precomputed integration
%    points, which depend on the simulation grid) are ignored.
%
% 2. A variable 'Trans' (Verasonics format). Only the one-way impulse
%    response Trans.IR1wy (sampled at 250 MHz) is used, for transmit and
%    receive. The geometry stays as in the catalogue.
%
% Impulse responses in PROTEUS are sampled continuous-time responses: the
% signal through the transducer is conv(V, IR)/SamplingRate (see
% get_pressure_signal and compute_RF), so a response with unit gain has
% max(abs(fft(IR)))/SamplingRate = 1, as estimate_impulse_response gives.
% Verasonics IR1wy is a discrete filter with unit gain and is multiplied
% by its sampling rate. Impulse responses in the PROTEUS format are used
% as they are: their scale sets the absolute transmit pressure in
% 'Voltage' amplitude mode and the scale of the RF data.

if nargin < 2
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    folder = fullfile(repoRoot, 'Transducer-models');
end

file = fullfile(folder, [Transducer.Type '.mat']);
if ~isfile(file)
    return
end

contents = whos('-file', file);
names = {contents.name};

if ismember('Transducer', names)
    S = load(file, 'Transducer');
    Model = S.Transducer;

    properties = {'NumberOfElements', 'Pitch', 'ElementWidth', ...
        'ElementHeight', 'ElevationFocus', 'Radius', 'Configuration', ...
        'BandwidthLow', 'BandwidthHigh', 'CenterFrequency'};
    for k = 1:numel(properties)
        if isfield(Model, properties{k})
            Transducer.(properties{k}) = Model.(properties{k});
        end
    end

    if all(isfield(Model, {'TransmitImpulseResponse', ...
            'ReceiveImpulseResponse', 'SamplingRate'}))
        IR_trans = Model.TransmitImpulseResponse;
        IR_rec   = Model.ReceiveImpulseResponse;
        Fs       = Model.SamplingRate;
    elseif all(isfield(Model, {'IR_trans', 'IR_rec', 'Fs_trans', 'Fs_rec'}))
        if Model.Fs_trans ~= Model.Fs_rec
            error('load_transducer_model:samplingRate', ...
                ['%s: the transmit and receive impulse responses must ' ...
                'have the same sampling rate.'], file)
        end
        IR_trans = Model.IR_trans;
        IR_rec   = Model.IR_rec;
        Fs       = Model.Fs_trans;
    else
        error('load_transducer_model:noImpulseResponse', ...
            '%s does not contain impulse responses.', file)
    end

elseif ismember('Trans', names)
    S = load(file, 'Trans');
    if ~isfield(S.Trans, 'IR1wy')
        error('load_transducer_model:noImpulseResponse', ...
            '%s does not contain Trans.IR1wy.', file)
    end
    Fs       = 250e6;   % Sampling rate of Verasonics impulse responses
    IR_trans = S.Trans.IR1wy*Fs;
    IR_rec   = S.Trans.IR1wy*Fs;

else
    error('load_transducer_model:unknownFormat', ...
        '%s contains neither a Transducer nor a Trans variable.', file)
end

Transducer.TransmitImpulseResponse = reshape(double(IR_trans), 1, []);
Transducer.ReceiveImpulseResponse  = reshape(double(IR_rec),   1, []);
Transducer.SamplingRate            = Fs;     % [Hz]
Transducer.ImpulseResponseType     = 'Calibrated';
Transducer.calibrated              = 1;

end
