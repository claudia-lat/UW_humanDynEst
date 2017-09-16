function missingData = loadPatientFileAndPlot
    % this script loads a given configuration of template data and plots
    % it, and can be used as a starting block for other batch commands

    % user setup
    basePath = 'C:\Documents\aslab\data'; % path of the data
    outputPath = 'C:\Documents\MATLABResults\DataPlots\'; % target path to write plot
    
    dataSourceGroup = {'healthy1', 'healthy2'}; % dataset to search
    patientList = []; % if empty, load all patient. If not empty, will load only those specific patients
    exercisePrefix = {}; % exercises to plot

    plotData = 1;
    
    for dataSourceInd = 1:length(dataSourceGroup);
    dataSource = dataSourceGroup{dataSourceInd};
	
    switch lower(dataSource)
        case 'healthy1'
            rawDataPath = [basePath '\Lowerbody_healthy1_2011-11'];
            
        case 'healthy2'
            rawDataPath = [basePath '\Lowerbody_healthy2_2013-07']; % path to the raw data
            
        case 'tri1'
            rawDataPath = [basePath  '\Lowerbody_TRI1_2012-10'];
            
        case 'stjoseph1'
            rawDataPath = [basePath  '\Lowerbody_StJoseph1_2013-02\'];
    end

    currTimestamp = datestr(now, 'yyyy-mm-dd-HH-MM-SS');
    outputBasePath = [outputPath dataSource '\fig_' currTimestamp '\'];
    
    specStruct.dataset = dataSource;
    specStruct.patient = patientList;
    specStruct.session = [];    
    specStruct.exerciseAcceptPrefix = exercisePrefix;
    
%     options.headerMocap = []; 
%     options.headerImu = [];
    % options.headerEkf = []; 
    % options.headerSegManual = [];
    % options.headerSegCrop = [];
    options.headerSegAlg = [];
   
    fileStack = loadPatientFilepaths(rawDataPath, specStruct);
    
    % make sure the output filepath exist
    checkMkdir(outputBasePath);
    
    % iterate through the subjectData and plot the data
    for ind_subjectData = 1:length(fileStack)
        % load each file separately so the memory usage isn't insane
        currFile = fileStack{ind_subjectData};
        currExerciseName = fileStack{ind_subjectData}.exerciseName;
               
        % load this specific EKF path
        options.headerEkf = fullfile(currFile.filePath, 'EKF', '2015_03_23', 'ekf.header'); 
        
        fprintf('%s (%u/%u): Reading %s\n', datestr(now), ind_subjectData, length(fileStack), currFile.filePath);
        subjectData = exerciseDataHandle(currFile.filePath, options);
        
        if isempty(subjectData)
            fprintf('  Skipping, no data loaded\n');
            continue
        end
        
        % load this specific manual segment
        subjectData.filepathHeaderSegManual = fullfile(subjectData.dirPathExercise, 'Segmentation_manual',  'SegmentData_Manual_Manual.header');
    
        if ~exist(subjectData.filepathHeaderSegManual, 'file')
            % no manual segments exists at all for this subject
            subjectData.filepathHeaderSegManual = [];
        end
        
        subjectData.load;

        % pad the subject or session number with a 0 if need be, for output
        subjStr = num2str(subjectData.subjectName);
        if length(subjStr) == 1
            subjStr = ['0' subjStr];
        end

        sessStr = num2str(subjectData.session);
        if length(sessStr) == 1
            sessStr = ['0' sessStr];
        end

        subjectBlurb = [upper(dataSource) '_' ...
            subjectData.exerciseType '_' ...
            'Subj' subjStr '_' ...
            'Sess' sessStr '_' ...
            subjectData.exerciseName];

        outputPathFig = fullfile(outputBasePath, [subjectBlurb '.fig']);
        outputPathJpg = fullfile(outputBasePath, [subjectBlurb '.png']);
        
        if isempty(subjectData.dataEkf) 

        else
            if plotData
                h = plotQdQ(subjectBlurb, ...
                    subjectData.dataEkf.time, ...
                    subjectData.dataEkf.Q, ...
                    subjectData.dataEkf.time, ...
                    subjectData.dataEkf.dQ, ...
                    subjectData.dataSegManual, ...
                    subjectData.dataSegCrop);
                
                saveas(h, outputPathFig);
                saveas(h, outputPathJpg);
                close(h);
            end
        end
    end
    end
end