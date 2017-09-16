function missingData = loadPatientFileAndPlot
    % this script loads a given configuration of template data and plots
    % it, and can be used as a starting block for other batch commands

    missingData = {};
    plotData = 1;
    dataSourceGroup = {'squats_tuat_2015'};
    
for dataSourceInd = 1:length(dataSourceGroup);
    dataSource = dataSourceGroup{dataSourceInd};

    basePath = 'C:\Documents\aslab\data';
    outputBase = 'C:\Documents\MATLABResults\DataPlots\';
    currTimestamp = datestr(now, 'yyyy-mm-dd-HH-MM-SS');
    outputBasePath = [outputBase dataSource '\pxBreakdown_paper_' currTimestamp '\'];
% outputBasePath = [outputBase dataSource '\evertsegment\'];
    
    specStruct.patient = []; % type in px numbers here, ie [1 5 7]
    specStruct.session = []; % type in the session number here, ie [1 4 6]
    specStruct.exercise = {}; % type in the movement names here. please be consistent with string length, ie {'KEFO_SUP', 'KHEF_SIT} or {'KEFO_SUP_NON1'}
    
%     specStruct.patient = [1];
%     specStruct.session = [20081209, 20090106, 20090203, 20090310];
%     specStruct.session = [20080813]; % type in the session number here, ie [1 4 6]
%     specStruct.patient = [2, 3]; % type in px numbers here, ie [1 5 7]
%     specStruct.session = [20080811]; % type in the session number here, ie [1 4 6]
%     specStruct.patient = [4]; % type in px numbers here, ie [1 5 7]
%     specStruct.session = [20080812]; % type in the session number here, ie [1 4 6]
%         specStruct.exercise = {'TAIS_STD_ONE2'}; % type in the movement names here. please be consistent with string length, ie {'KEFO_SUP', 'KHEF_SIT} or {'KEFO_SUP_NON1'}

    specStruct.manSeg = 'Segmentation_manual_JL';
    specStruct.exerciseCropLength = '';
    specStruct.dataset = dataSource;
    specStruct.datasetSpecs = datasetSpecs(dataSource);
    
    options.headerMocap = []; 
%     options.headerImu = [];
    % options.headerEkf = []; 
    % options.headerSegManual = [];
    % options.headerSegCrop = [];
    options.headerSegAlg = [];
   
    fileStack = dataGeneral_generateFilestack(basePath, specStruct);
%     fileStack = loadPatientFilepaths(pathToRawData, specStruct);
    
    % make sure the output filepath exist
    checkMkdir(outputBasePath);
    
    % iterate through the subjectData and plot the data
    for ind_subjectData = 1:length(fileStack)
        % load each file separately so the memory usage isn't insane
        currFile = fileStack{ind_subjectData};
        
        fprintf('Loading %u/%u: %s\n', ind_subjectData, length(fileStack), currFile.filePath);
        
        if ~exist(currFile.filepathDataSegManual, 'file')
            fprintf('    No manual segment file detected. skipping...\n');
            continue
        end
        
        switch currFile.datasetName
            case {'squats_tuat_2011', 'squats_tuat_2015', 'doppel', 'taiso_ut_2009'}
                subjectData = exerciseDataHandle_generalized(currFile);
                subjectData.load;
                
            otherwise % APARS file format
                subjectData = exerciseDataHandle(currSubjInfo);
                subjectData.load;
        end
        
        forceLoaded = subjectData.dataForces;
        ekfLoaded = subjectData.dataEkf;
        segmentCropLoaded = subjectData.dataSegCrop;
        segmentManualLoaded = subjectData.dataSegManual; % well...the class is too rigid for the purposes of this fct
        
%         if isempty(ekfLoaded) || isempty(ekfLoaded.Q)
%             continue
%         end        
%         
%         if isempty(segmentCropLoaded)
%             continue
%         end
        
% % %         % load this specific EKF path
% % %         jointAngleFile = searchForFileByExt(fullfile(currFile.filePath, 'JointAngles', 'IK_MK'), 'mat');
% % %         options.headerEkf = fullfile(currFile.filePath, 'JointAngles', 'IK_MK', jointAngleFile); 
% % %         
% % %         if isempty(jointAngleFile)
% % %             continue
% % %         end
% % %         
% % % %         options.headerEkf = fullfile(currFile.filePath, 'JointAngles', 'IK_MK', 'ekf.header'); 
% % %         options.headerSegManual = fullfile(currFile.filePath, 'Segmentation_manual_MK',  'SegmentData_Manual_Manual.header');
% % %         
% % %         fprintf('%s (%u/%u): Reading %s\n', datestr(now), ind_subjectData, length(fileStack), currFile.filePath);
% % %         subjectData = exerciseDataHandle(currFile.filePath, options);
% % %         
% % %         if isempty(subjectData)
% % %             continue
% % %         end
% % % 
% % %         subjectData.load;

        subjStr = num2str(subjectData.subjectName);
        if length(subjStr) == 1
            subjStr = ['0' subjStr];
        end

        sessStr = num2str(subjectData.session);
        if length(sessStr) == 1
            sessStr = ['0' sessStr];
        end

% % % %         subjectBlurb = [dataSource '_' ...
% % % %             'Subj' subjStr '_' ...
% % % %             'Sess' sessStr '_' ...
% % % %             subjectData.exerciseName];

        subjectBlurb = [upper(dataSource) '_' ...
            subjectData.exerciseType '_' ...
            'Subj' subjStr '_' ...
            'Sess' sessStr '_' ...
            subjectData.exerciseName];

        missingData{end+1, 1} = subjectData.dirPathExercise;
        missingData{end, 2} = ~isempty(subjectData.dataEkf);
        missingData{end, 3} = ~isempty(subjectData.dataSegManual);
        %             missingData{end, 4} = isempty(subjectData.dataSegCrop);
        
        subBlurb = '_combined_dfilt';
        % calc the diff for plotting
        
%         dofMapping = [27 34 33 36 23] - 3;
%         dt = mean(diff(ekfLoaded.time));
%         time1ToPlot = ekfLoaded.time;
%         data1ToPlot = ekfLoaded.Q(:, dofMapping);
        
        time1ToPlot = ekfLoaded.time;
        data1ToPlot = ekfLoaded.Q(:, :);

%         if strcmpi(subjStr, '02')
%              data1ToPlot(28000:end, 5) = -abs(data1ToPlot(28000:end, 5));
%         end
%         
%         if strcmpi(subjStr, '04')
%             data1ToPlot(:, 1) = abs(data1ToPlot(:, 1)) - 180;
%             data1ToPlot(:, 3) = abs(data1ToPlot(:, 3)) - 360;
%         end
%         
%         subjectData.dataSegManual
%         temp = [subjectData.dataSegManual.timeStart; subjectData.dataSegManual.timeEnd];
%         temp2 = sort(temp);
%         subjectData.dataSegManual.timeStart = temp2(1:2:(length(temp2)-1));
%         subjectData.dataSegManual.timeEnd = temp2(2:2:length(temp2)); 
        
        
        time2ToPlot = ekfLoaded.time;
        data2ToPlot = ekfLoaded.dQ(:, :);
%         diff_dataToPlot = [zeros(1, size(dataToPlot, 2)); diff(dataToPlot)]/dt;
        
        outputPathFig = fullfile(outputBasePath, [subjectBlurb subBlurb '_2d.fig']);
        outputPathJpg = fullfile(outputBasePath, [subjectBlurb subBlurb '_2d.jpg']);
        outputPathFig2 = fullfile(outputBasePath, [subjectBlurb subBlurb '_3d.fig']);
        outputPathJpg2 = fullfile(outputBasePath, [subjectBlurb subBlurb '_3d.jpg']);
        
        if isempty(subjectData.dataEkf) %|| isempty(subjectData.dataSegManual) %|| isempty(subjectData.dataSegCrop)

        else

            if plotData
                h = plot2xTimeSeries(subjectBlurb, ...
                    time1ToPlot,      data1ToPlot, ...
                    time2ToPlot,      data2ToPlot, ...
                    subjectData.dataSegManual, subjectData.dataSegCrop); % subjectData.dataSegCrop
                
                if ~isempty(subjectData.dataSegGuidance)
                    subplot(211);
                    plotBoxes(h, subjectData.dataSegGuidance.timeStart, subjectData.dataSegGuidance.timeEnd, 'b');
                    
                    subplot(212);
                    plotBoxes(h, subjectData.dataSegGuidance.timeStart, subjectData.dataSegGuidance.timeEnd, 'b');
                end
                
%                 ylim([-2*pi-0.5 2*pi+0.5])
                
                hold on
                
%                 for k = -2*pi:pi:2*pi
%                     plot([0 time1ToPlot(end)], [k k], 'k');
%                 end
                
%                 h2 = plot1x3D(subjectBlurb, ...
%                     timeToPlot, dataToPlot(:, 1), dataToPlot(:, 2), dataToPlot(:, 3), ...
%                     subjectData.dataSegManual, []); % subjectData.dataSegCrop
                
                saveas(h, outputPathFig);
                saveas(h, outputPathJpg);
                close(h);
                
%                 saveas(h2, outputPathFig2);
%                 saveas(h2, outputPathJpg2);
%                 close(h2);
            end
        end
    end
end
    
    missingData
    save([outputBase '\missingData_' currTimestamp], 'missingData');
end