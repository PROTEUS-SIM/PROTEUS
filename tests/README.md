# PROTEUS tests

```matlab
cd tests
results = runProteusTests();                 % everything
results = runProteusTests(Tag="Fast");       % quick unit tests only
results = runProteusTests(ReportFolder="test-results"); % + JUnit/coverage
```

* `RegressionTest` – golden-master tests: re-runs every case in
  `helpers/regression_cases.m` and compares with `baseline/` (see
  `baseline/README.md`).
* `UpdateSensorTest` – `update_sensor_fast` must reproduce `update_sensor`.
* `ProteusTestEnvironment` – shared fixture: sets the MATLAB path, creates
  temporary result/settings/ground-truth folders, a tiny synthetic flow
  geometry, and points `path_setup` to them.
* `shims/kspaceFirstOrder3DC.m` – replaces the k-Wave C++ solver by the
  MATLAB solver, so no compiled binaries (or GPU) are needed.

Requirements: MATLAB with the Signal Processing Toolbox. Cases running
full simulations additionally need k-Wave (in `external/k-wave/k-Wave` or
`PROTEUS_KWAVE_PATH`); they are skipped (reported as *incomplete*) when it
is missing. `TruncatedNormalTest` compares PROTEUS's base-MATLAB
truncated-normal sampler with the Statistics and Machine Learning Toolbox
and is skipped when that toolbox is not installed (CI installs it).
