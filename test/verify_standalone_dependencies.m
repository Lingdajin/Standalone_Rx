function requiredFiles = verify_standalone_dependencies()
%VERIFY_STANDALONE_DEPENDENCIES 检查入口和测试是否引用项目外部文件。

projectRoot = fileparts(mfilename('fullpath'));
entries = {
    fullfile(projectRoot, 'PDSCH_Receiver_Standalone.m')
    fullfile(projectRoot, 'PDSCH_Receiver_Standalone_Config.m')
    fullfile(projectRoot, 'PDSCH_Init_Standalone.m')
    fullfile(projectRoot, 'test_cp_frequency_offset_estimate.m')
    fullfile(projectRoot, 'test_cp_timing_metric.m')
    fullfile(projectRoot, 'test_load_standalone_vsa.m')
    fullfile(projectRoot, 'test_nr_dmrs_fd_occ_despread.m')
    };

[requiredFiles, products] = matlab.codetools.requiredFilesAndProducts(entries);
projectPrefix = lower([char(java.io.File(projectRoot).getCanonicalPath()), filesep]);
matlabPrefix = lower([char(java.io.File(matlabroot).getCanonicalPath()), filesep]);
externalFiles = {};
for fileIndex = 1:numel(requiredFiles)
    canonicalFile = lower(char(java.io.File(requiredFiles{fileIndex}).getCanonicalPath()));
    if ~startsWith(canonicalFile, projectPrefix) && ~startsWith(canonicalFile, matlabPrefix)
        externalFiles{end + 1} = requiredFiles{fileIndex}; %#ok<AGROW>
    end
end

if ~isempty(externalFiles)
    error('发现独立项目外部依赖:\n%s', strjoin(externalFiles, newline));
end

fprintf('依赖检查通过: %d 个项目文件，MATLAB 产品: %s。\n', ...
    numel(requiredFiles), strjoin({products.Name}, ', '));
end
