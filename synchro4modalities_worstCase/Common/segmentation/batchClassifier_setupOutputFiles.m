[currTrainingPxStr, currTestingPxStr, pxStr] = setupOutputConfigNames(currTrainingPackage, currTestingPackage, dataSelect);

exportSuffix = [dataSelect.settings.settingName '_' dimReductSelect.settingName '_' classifierSelect.settingName '_' aggregatorSelect.settingName];

if length(exportSuffix) > 25 % this prevents the filepath strings from getting too long, which can cause MATLAB to error out
    exportSuffix = exportSuffix(1:25);
end

% set up the actual file paths for the various outputs
exportPrefix = fullfile(dataSelect.exportBasePath, batchSettings.batchInstancePath, batchSettings.exportPathSuffix, pxStr);
exportPath = fullfile(exportPrefix, currTestingPackage{1}.exerciseAcceptPrefixString{1});

overallSummaryTestingPath  = fullfile(exportPrefix, [batchSettings.exportPathSuffix '_summary_overall.csv']);
instanceSummaryTestingPath = fullfile(exportPrefix, [batchSettings.exportPathSuffix '_summary_instance.csv']);
overallCSVTrainingPath     = fullfile(exportPrefix, ['score_Training.csv']);
overallCSVTestingPath      = fullfile(exportPrefix, ['score_Testing.csv']);
exportPathInstance         = fullfile(exportPath, exportSuffix);
instanceDiary              = [exportPathInstance '_diary.txt'];
instanceCSVTrainingPath    = [exportPathInstance '_Training.csv'];
instanceCSVTestingPath     = [exportPathInstance '_Testing.csv'];

checkMkdir(exportPath);
checkMkdir(exportPathInstance);