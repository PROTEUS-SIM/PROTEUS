function results = runProteusTests(options)
%RUNPROTEUSTESTS Run the PROTEUS test suite (locally or in CI).
%
% results = RUNPROTEUSTESTS() runs all tests in this folder.
% results = RUNPROTEUSTESTS(Tag="Fast") runs only tests with that tag.
% RUNPROTEUSTESTS(ReportFolder="test-results") also writes a JUnit XML
% report and a Cobertura coverage report of the PROTEUS modules.

arguments
    options.Tag (1,:) char = ''
    options.ReportFolder (1,:) char = ''
end

import matlab.unittest.TestRunner
import matlab.unittest.TestSuite
import matlab.unittest.plugins.XMLPlugin
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat

here = fileparts(mfilename('fullpath'));
root = fileparts(here);

suite = TestSuite.fromFolder(here, 'IncludingSubfolders', false);
if ~isempty(options.Tag)
    suite = suite.selectIf('Tag', options.Tag);
end

runner = TestRunner.withTextOutput('OutputDetail', 2);

if ~isempty(options.ReportFolder)
    if ~isfolder(options.ReportFolder)
        mkdir(options.ReportFolder);
    end
    runner.addPlugin(XMLPlugin.producingJUnitFormat( ...
        fullfile(options.ReportFolder,'junit.xml')));
    modules = fullfile(root, {'acoustic-module','GUIfunctions', ...
        'delay-and-sum','microbubble-simulator','streamline-module'});
    runner.addPlugin(CodeCoveragePlugin.forFolder(modules, ...
        'IncludingSubfolders', true, 'Producing', ...
        CoberturaFormat(fullfile(options.ReportFolder,'coverage.xml'))));
end

results = runner.run(suite);
disp(table(results));
end
