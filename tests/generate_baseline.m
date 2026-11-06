function generate_baseline(caseNames)
%GENERATE_BASELINE Record golden-master outputs in tests/baseline.
%
% GENERATE_BASELINE() records every case of regression_cases() whose
% requirements are met. GENERATE_BASELINE(caseNames) records only the
% listed cases (cell array of names).
%
% Baselines must be recorded on the reference version of the code (see
% tests/baseline/README.md), never on a version under test.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'helpers'));

% applyFixture tears the environment down (restoring the MATLAB path and
% the path configuration) when tc is cleared, even if a case errors.
tc  = matlab.unittest.TestCase.forInteractiveUse;
env = tc.applyFixture(ProteusTestEnvironment);

C = regression_cases();
if nargin > 0
    C = C(ismember({C.name}, caseNames));
end

[~, commit] = system(sprintf('git -C "%s" rev-parse HEAD', env.RepoRoot));
meta.commit       = strtrim(commit);
meta.matlab       = version;
meta.kWavePath    = env.KWavePath;
meta.date         = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
meta.computer     = computer;

for k = 1:numel(C)
    [ok, missing] = env.meetsRequirements(C(k).requires);
    if ~ok
        fprintf('SKIP %-26s missing %s\n', C(k).name, strjoin(missing,', '));
        continue
    end
    rng(0,'twister');
    expected = C(k).fcn(env); %#ok<NASGU>
    file = fullfile(here,'baseline',[C(k).name '.mat']);
    save(file,'expected','meta');
    fprintf('SAVE %-26s %s\n', C(k).name, file);
end
end
