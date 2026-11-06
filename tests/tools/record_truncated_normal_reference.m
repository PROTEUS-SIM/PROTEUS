function record_truncated_normal_reference()
%RECORD_TRUNCATED_NORMAL_REFERENCE Record the Statistics and Machine
%Learning Toolbox draws reproduced by random_truncated_normal.
%
% Writes tests/baseline/truncated_normal.mat with the draws of
% random(truncate(makedist('Normal'),-c,c), sz) (as in the original
% define_medium) for several seeds, cutoffs and sizes, and the next
% uniform number of the global stream after each draw. TruncatedNormalTest
% compares random_truncated_normal with these values, so the toolbox is
% not needed to run the tests. Requires the toolbox.

if isempty(ver('stats')) || ~license('test','Statistics_Toolbox')
    error('Requires the Statistics and Machine Learning Toolbox.')
end

cases = struct('seed',{},'cutoff',{},'size',{},'x',{},'next',{});
for seed = [0 3 42]
    for cutoff = [1 2 2.5 3]
        cases(end+1) = draw(seed, cutoff, [7 11 13]); %#ok<AGROW>
    end
end
cases(end+1) = draw(42, 2.5, [32 32 32]);

meta.matlab = version;
meta.stats  = ver('stats');
meta.date   = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));

here = fileparts(fileparts(mfilename('fullpath')));
save(fullfile(here,'baseline','truncated_normal.mat'),'cases','meta');
end

function c = draw(seed, cutoff, sz)
old = rng; restore = onCleanup(@() rng(old));
pd = truncate(makedist('Normal'), -cutoff, cutoff);
rng(seed,'twister');
c.seed   = seed;
c.cutoff = cutoff;
c.size   = sz;
c.x      = random(pd, sz);
c.next   = rand;
end
