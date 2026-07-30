function results = run_standalone_tests()
%RUN_STANDALONE_TESTS 在仅加载本项目路径的环境中运行全部回归测试。

projectRoot = fileparts(mfilename('fullpath'));
originalPath = path;
cleanupPath = onCleanup(@() path(originalPath)); %#ok<NASGU>

restoredefaultpath;
addpath(projectRoot);
Sim_Add_Path_Minimal;

testFiles = {
    fullfile(projectRoot, 'test_cp_frequency_offset_estimate.m')
    fullfile(projectRoot, 'test_cp_timing_metric.m')
    fullfile(projectRoot, 'test_load_standalone_vsa.m')
    fullfile(projectRoot, 'test_nr_dmrs_fd_occ_despread.m')
    };

results = runtests(testFiles);
disp(table(results));
assertSuccess(results);
verify_standalone_dependencies;
end
