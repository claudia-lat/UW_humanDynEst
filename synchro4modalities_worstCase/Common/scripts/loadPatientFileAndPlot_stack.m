function missingData = loadPatientFileAndPlot
    % this script loads a given configuration of template data and plots
    % it, and can be used as a starting block for other batch commands

     missingData = {};
     plotData = 1;
    specStruct.blackList = 1;
    
    % set up parameters
    dataSourceGroup = {'healthy1'};

%     dataSourceGroup = {'healthy1','healthy2','tri1', 'stjoseph1'};

    for dataSourceInd = 1:length(dataSourceGroup);
        dataSource = dataSourceGroup{dataSourceInd};

%         outputBasePath = ['D:\MATLABResults\DataPlots\' dataSource '\pxBreakdown_' datestr(now, 'yyyy-mm-dd-HH-MM-SS') '\'];
      
    outputBase = 'C:\Documents\MATLABResults\DataPlots\';
    currTimestamp = datestr(now, 'yyyy-mm-dd-HH-MM-SS');
    outputBasePath = [outputBase dataSource '\pxBreakdown_blacklistCheck_' currTimestamp '\'];
    
    specStruct.dataset = dataSource;
    specStruct.patient = [3];
    specStruct.session = [];    
    specStruct.exerciseAcceptPrefix = [];
%     specStruct.exerciseAcceptPrefix = ...
%         {'HFEO_SUP', 'KEFO_SIT', 'KHEF_SUP', 'SQUA_STD', 'STSO_SIT', ...
%         'HAAO_STD', 'HAAO_SUP', 'HEFO_STD', 'HFEO_STD', 'KFEO_STD', 'KHEF_STD', 'LUNG_STD'};
    
    specStruct.exerciseAcceptPrefix = {'KEFO_SIT_SLO'}; % set used for paper
    
% % submitted list
%     specStruct.exerciseAcceptPrefix = {'HAAO_STD', 'HAAL_STD', 'HEFO_STD', 'HFEO_STD', ....
%          'KEFO_SIT', 'KFEO_SIT', 'KHEF_STD', 'KHEF_SUP'}; % set used for paper
    
%     specStruct.exerciseAcceptPrefix = {'HAAO_STD', 'HAAL_STD', 'HEFO_STD', 'HFEO_STD', 'KEFO_SIT', 'KFEO_SIT', 'KHEF_STD', 'KHEF_SUP', ...
%         'HAAO_SUP', 'HFEO_SUP', 'KFEO_STD', 'KEFO_SUP', 'KFEO_SUP', 'LUNG_STD', 'SQUA_STD'}; % all
    
%     specStruct.exerciseRejectSuffix = {'FAS', 'MED', 'FWD', 'REV'};    
    
    % healthy1: 'HFEO_SUP', 'KEFO_SIT', 'KHEF_SUP', 'SQUA_STD', 'STSO_SIT'
    % healthy2: 'HAAO_STD', 'HEFO_STD', 'HFEO_STD', 'KFEO_STD', 'KHEF_STD', 'LUNG_STD'
    % TRI only (incomplete): 'KEFO_SUP', 'KFEO_SIT', 'KFEO_STD', 'KFEO_SUP'
    % TRI only (sag): 'HEFO_STD' 'HFEO_STD' 'HFEO_SUP' 'KEFO_SIT', 'KEFO_SUP' 'KFEO_SIT' 'KFEO_STD' 'KFEO_SUP' 'KHEF_STD' 'KHEF_SUP'

    basePath = 'C:\Documents\aslab\data';
%     basePath = 'D:\MyDocument\MotionData';
    switch lower(dataSource)
        case 'healthy1'
            pathToRawData = [basePath '\Lowerbody_healthy1_2011-11'];
            
        case 'healthy2'
            pathToRawData = [basePath '\Lowerbody_healthy2_2013-07']; % path to the raw data
            
        case 'tri1'
            pathToRawData = [basePath  '\Lowerbody_TRI1_2012-10'];
            
        case 'stjoseph1'
            pathToRawData = [basePath  '\Lowerbody_StJoseph1_2013-02\'];
    end


    options.headerMocap = []; 
%     options.headerImu = [];
    % options.headerEkf = []; 
    % options.headerSegManual = [];
    % options.headerSegCrop = [];
    options.headerSegAlg = [];
   
    fileStack = loadPatientFilepaths(pathToRawData, specStruct);
    
    % make sure the output filepath exist
    checkMkdir(outputBasePath);
    
    % iterate through the subjectData and plot the data
    for ind_subjectData = 1:length(fileStack)
        % load each file separately so the memory usage isn't insane
        currFile = fileStack{ind_subjectData};
        currExerciseName = fileStack{ind_subjectData}.exerciseName;
               
        % load this specific EKF path
%         options.headerEkf = fullfile(currFile.filePath, 'EKF', '2013_06_13', ['JointAngle_' currExerciseName '.data']);
      options.headerEkf = fullfile(currFile.filePath, 'EKF', '2015_03_23', 'ekf.header'); 

%         options.headerSegManual = fullfile(currFile.filePath, 'Segmentation_manual_annotatedZVC',  'SegmentData_Manual_Manual.header');
        
        fprintf('%s (%u/%u): Reading %s\n', datestr(now), ind_subjectData, length(fileStack), currFile.filePath);
        subjectData = exerciseDataHandle(currFile.filePath, options);
        
        if isempty(subjectData)
            fprintf('  Skipping, no data loaded\n');
            continue
        end
        
%         manSegPath1 = fullfile(dirPathExercise, 'Segmentation_manual',  'SegmentData_Manual_Manual.data');
%         manSegPath1 = fullfile(dirPathExercise, 'Segmentation_manual_annotatedZVCHalfSeg',  'SegmentData_Manual_Manual.header');
        subjectData.filepathHeaderSegManual = fullfile(subjectData.dirPathExercise, 'Segmentation_manual_annotatedZVC',  'SegmentData_Manual_Manual.header');
        
        if ~exist(subjectData.filepathHeaderSegManual, 'file') && strcmpi(dataSource, 'healthy1')
            % no manual segments exists at all for this subject
            subjectData.filepathHeaderSegManual = fullfile(subjectData.dirPathExercise, 'Segmentation_manual',  'SegmentData_Manual_Manual.header');
        end
        
        if ~exist(subjectData.filepathHeaderSegManual, 'file')
            % no manual segments exists at all for this subject
            subjectData.filepathHeaderSegManual = [];
        end
        
        if isempty(subjectData.filepathHeaderSegManual) || ...
                ~exist(subjectData.filepathHeaderSegManual, 'file') || ...
                ~exist(subjectData.filepathHeaderEkf, 'file')
            fprintf('  Skipping, missing EKF or manseg\n');
            continue
            %             subjectData.filepathHeaderSegManual = manSegPath1;
        end
        
        subjectData.load;

        subjStr = num2str(subjectData.subjectName);
        if length(subjStr) == 1
            subjStr = ['0' subjStr];
        end

        sessStr = num2str(subjectData.session);
        if length(sessStr) == 1
            sessStr = ['0' sessStr];
        end

%         subjectBlurb = [dataSource '_' ...
%             'Subj' subjStr '_' ...
%             'Sess' sessStr '_' ...
%             subjectData.exerciseName];

        subjectBlurb = [upper(dataSource) '_' ...
            subjectData.exerciseType '_' ...
            'Subj' subjStr '_' ...
            'Sess' sessStr '_' ...
            subjectData.exerciseName];

        outputPathFig = fullfile(outputBasePath, [subjectBlurb '.fig']);
        outputPathJpg = fullfile(outputBasePath, [subjectBlurb '.png']);
        
        missingData{end+1, 1} = subjectData.dirPathExercise;
        missingData{end, 2} = ~isempty(subjectData.dataEkf);
        missingData{end, 3} = ~isempty(subjectData.dataSegManual);
        %             missingData{end, 4} = isempty(subjectData.dataSegCrop);
        
        if isempty(subjectData.dataEkf) %|| isempty(subjectData.dataSegManual) %|| isempty(subjectData.dataSegCrop)

        else
            h = figure;
            t = subjectData.dataEkf.time - 0;
            q = subjectData.dataEkf.Q;
            q = q - repmat(q(5, :), size(q, 1), 1);
             
            plot(t, q(:, 1), 'Color', [0.6 0.1 0.6], 'DisplayName', 'Hip Ext', 'LineWidth', 2); hold on
            plot(t, q(:, 2), 'Color', [0.1 0.6 0.6], 'DisplayName', 'Hip Abd', 'LineWidth', 2);
            plot(t, q(:, 4), 'Color', [0.6 0.6 0.1], 'DisplayName', 'Knee Ext', 'LineWidth', 2);

            plotBoxes(h, subjectData.dataSegManual.timeStart, subjectData.dataSegManual.timeEnd, 'b', 0, 1.5, -0.2);
            plotBoxes(h, subjectData.dataSegManual.timeStart, ...
                subjectData.dataSegManual.timeEnd - rand(size(subjectData.dataSegManual.timeEnd))/1.5, 'r', 0, 1.6, -0.1);
            
%             for ind_seg = 2:length(subjectData.dataSegManual.timeStart)-1
%                 [valStart, indStart] = findClosestValue(subjectData.dataSegManual.timeStart(ind_seg), subjectData.dataEkf.time);
%                 [valEnd, indEnd] = findClosestValue(subjectData.dataSegManual.timeEnd(ind_seg), subjectData.dataEkf.time);
%                 
%                 indStart = indStart - 2;
%                 indEnd = indEnd ;
%                 
%                 t = subjectData.dataEkf.time(indStart:indEnd) - valStart;
%                 q = subjectData.dataEkf.Q(indStart:indEnd, :);
%                 q = q - repmat(q(1, :), size(q, 1), 1);
%                 hold on
%                 plot(t, q(:, 1), 'Color', [0.6 0.1 0.6], 'DisplayName', 'Hip Ext', 'LineWidth', 2); 
%                 plot(t, q(:, 2), 'Color', [0.1 0.6 0.6], 'DisplayName', 'Hip Abd', 'LineWidth', 2);
%                 plot(t, q(:, 4), 'Color', [0.6 0.6 0.1], 'DisplayName', 'Knee Ext', 'LineWidth', 2);
%                 
%                 set(gca, 'FontSize', 14);
%                 
%                 xlabel('Time [s]');
%                 ylabel('Joint Angle [rad]');
%                 
% %                 hold on
% %                 plot(t, q);
%             end
        end
    end
    end
    
    missingData
    save([outputBase '\missingData_' currTimestamp], 'missingData');
end