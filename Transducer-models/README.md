# Calibrated transducer models

A file `<Type>.mat` in this folder (for example `C1-6D.mat`) marks the
catalogue transducer `<Type>` as calibrated: `get_transducer_properties`
applies it through `load_transducer_model`, and its impulse responses take
precedence over the estimate from the bandwidth. Without a file, the
transducer uses the catalogue values and an estimated impulse response.

Accepted contents:

1. A `Transducer` struct (PROTEUS format).
   - Optional geometry and band, replacing the catalogue values:
     `NumberOfElements`, `Pitch`, `ElementWidth`, `ElementHeight`,
     `ElevationFocus`, `Radius`, `Configuration`, `BandwidthLow`,
     `BandwidthHigh`, `CenterFrequency` (SI units).
   - Impulse responses: `TransmitImpulseResponse`, `ReceiveImpulseResponse`
     and `SamplingRate`, or `IR_trans`, `IR_rec`, `Fs_trans` and `Fs_rec`
     (equal sampling rates).
   - Other fields are ignored, in particular integration points: they
     depend on the simulation grid and are recomputed for each simulation,
     in the PROTEUS orientation (x axial, y lateral, z elevation). Only
     orientation-free quantities (lengths, angles, responses) are read.
2. A Verasonics `Trans` struct: only `Trans.IR1wy` (one-way, 250 MHz) is
   used, for transmit and receive.

Scale of the impulse responses: the signal through the transducer is
`conv(V, IR)/SamplingRate`, so a response with unit gain has
`max(abs(fft(IR)))/SamplingRate = 1` (as the estimated response). In the
default 'Pressure' amplitude mode the transmit pulse is scaled to the
requested pressure anyway; the scale matters in 'Voltage' mode and for the
RF amplitude.

Only add files from a calibration measurement (for example hydrophone
measurements of the field for a known excitation). Updating a file changes
every simulation with that transducer.
