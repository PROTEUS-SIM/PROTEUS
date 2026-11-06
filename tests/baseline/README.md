# Regression baselines

Each `<case>.mat` file holds the outputs (`expected`) of one case in
`tests/helpers/regression_cases.m`, plus provenance (`meta`: commit,
MATLAB version, k-Wave path, date).

**Reference code version:** upstream `PROTEUS-SIM/PROTEUS` branch
`transducer-calibration` at `6a863b4`, i.e. the code base *before* the
revamp. Baselines must only be (re)recorded from that reference, never from
a version under test:

```matlab
% in a checkout/worktree of the reference commit with tests/ copied in
cd tests
generate_baseline()                       % all cases whose requirements are met
generate_baseline({'rf_hybrid_standard'}) % selected cases
```

Cases that need k-Wave (`rf_*`, `pressure_field`,
`homogeneous_propagation`, `bubble_mass_source`) are skipped when it is
unavailable. The end-to-end baselines were recorded with the original
`define_medium`, which used the Statistics and Machine Learning Toolbox;
its base-MATLAB replacement reproduces them bit for bit.

An intentional change of behaviour (a bug fix, a new default) must update
the affected baseline in the same commit, and the commit message must say
why.

`truncated_normal.mat` is not a regression case: it holds draws of the
Statistics and Machine Learning Toolbox (`random(truncate(makedist(...)))`,
as in the original `define_medium`) for `TruncatedNormalTest`, recorded with
`tests/tools/record_truncated_normal_reference.m`. With it, the tests (and
CI) run without the toolbox.

