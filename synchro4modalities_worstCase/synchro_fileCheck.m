clc;
clear;
close all;

addpath(genpath('xml_io_tools'));
addpath(genpath('mocap_tools'));

%% settings
filepath_dataroot  = 'D:/aslab/data/Fullbody_IIT_2017/';
filepath_filemapping = 'D:/aslab/data/Fullbody_IIT_2017/databaseSpec.csv';
filepath_plots = 'D:/aslab/data/Fullbody_IIT_2017/plots/'; 

totalSubj = 1:11;
totalExercise = 1:11;
mvnTimestampRow = 597;
filepath_unloadefp = 'unloaded_fp1.anc';

%% setup
if ~exist(filepath_plots, 'dir')
    mkdir(filepath_plots)
end

%% load filelist
[numData,textData,rawData] = xlsread(filepath_filemapping);

% now parse them into individual entries
fileSetInd = 0;
for ind_subj = totalSubj
    for ind_motion = totalExercise
        subjOverallInd = 4 + 4*(ind_subj-1);
        exerOverallInd = 6 + ind_motion;
        fileSet.subject = rawData{subjOverallInd, 1}(end-1:end);
        fileSet.exercise = rawData{3, exerOverallInd};
        fileSet.exerciseId = ind_motion;
        fileSet.filepath_output = [filepath_plots 'subject' fileSet.subject '_exercise' num2str(ind_motion)];
        
        % xsens
        modalityFileRawInd = rawData{subjOverallInd + 0, exerOverallInd};
        modalityFileInd = prepadZeros(modalityFileRawInd, 3);
        if ~isempty(modalityFileInd)
            modalityFilePath = ['mvn/Subject_' fileSet.subject '-' modalityFileInd '.mvnx'];
            fileSet.filepath_xsens = [filepath_dataroot 'Subject' fileSet.subject '/' modalityFilePath];
        else
            fileSet.filepath_xsens = [];
        end
        
        % shoes
        modalityFileRawInd = rawData{subjOverallInd + 1, exerOverallInd};
        modalityFileInd = prepadZeros(modalityFileRawInd, 5);
        if ~isempty(modalityFileInd)
            modalityFilePath = ['yarp/dump_onlyDriverForces/ftShoeDriver_Left/totalForce_' modalityFileInd '/' 'data.log'];
            fileSet.filepath_shoes_left = [filepath_dataroot 'Subject' fileSet.subject '/' modalityFilePath];
            modalityFilePath = ['yarp/dump_onlyDriverForces/ftShoeDriver_Right/totalForce_' modalityFileInd '/' 'data.log'];
            fileSet.filepath_shoes_right = [filepath_dataroot 'Subject' fileSet.subject '/' modalityFilePath];
        else
            fileSet.filepath_shoes_left = [];
            fileSet.filepath_shoes_right = [];
        end

        % mocap
        modalityFileRawInd = rawData{subjOverallInd + 2, exerOverallInd};
        modalityFileInd = prepadZeros(modalityFileRawInd, 0);
        if ~isempty(modalityFileInd)
            modalityFilePath = ['mocap_fp/exercise' modalityFileInd '.trc'];
            fileSet.filepath_mocap = [filepath_dataroot 'Subject' fileSet.subject '/' modalityFilePath];
        else
            fileSet.filepath_mocap = [];
        end
        
        % fp
        modalityFileRawInd = rawData{subjOverallInd + 3, exerOverallInd};
        modalityFileInd = prepadZeros(modalityFileRawInd, 0);
        if ~isempty(modalityFileInd)
            modalityFilePath = ['mocap_fp/exercise' modalityFileInd '.anc'];
            fileSet.filepath_fp = [filepath_dataroot 'Subject' fileSet.subject '/' modalityFilePath];
            modalityFilePath = ['mocap_fp/' filepath_unloadefp];
            fileSet.filepath_fpUnloaded = [filepath_dataroot 'Subject' fileSet.subject '/' modalityFilePath];
        else
            fileSet.filepath_fp = [];
            fileSet.filepath_fpUnloaded = [];
        end

        % combine
        fileSetInd = fileSetInd + 1;
        totalFileSet(fileSetInd) = fileSet;
    end
end

% parse through the listing to find missing files
for ind_fileset = 1:length(totalFileSet)
    currFileSet = totalFileSet(ind_fileset);
    
    checkPathWriteToConsole(currFileSet.filepath_xsens, currFileSet);
    checkPathWriteToConsole(currFileSet.filepath_shoes_left, currFileSet);
    checkPathWriteToConsole(currFileSet.filepath_shoes_right, currFileSet);
    checkPathWriteToConsole(currFileSet.filepath_mocap, currFileSet);
    checkPathWriteToConsole(currFileSet.filepath_fp, currFileSet);
    checkPathWriteToConsole(currFileSet.filepath_fpUnloaded, currFileSet);
end

 
for ind_fileset = 1:length(totalFileSet)
    currFileSet = totalFileSet(ind_fileset);
    
    filepath_mocap = currFileSet.filepath_mocap;
    filepath_fp    = currFileSet.filepath_fp;
    filepath_fpUnloaded = currFileSet.filepath_fpUnloaded;
    filepath_mvn        = currFileSet.filepath_xsens;
    filepath_san_left   = currFileSet.filepath_shoes_left;
    filepath_san_right  = currFileSet.filepath_shoes_right;
    
    filepath_output     = currFileSet.filepath_output;
    filepath_output_png       = [filepath_output '.png'];
    filepath_output_fig       = [filepath_output '.fig'];
    
    %% extracting data and aligning
    % --------- xsens timestamp ---------
    % read
    if ~isempty(filepath_mvn) && exist(filepath_mvn, 'file')
        fid = fopen(filepath_mvn);
        mvnDataRow = textscan(fid, '%[^\n]', 1, 'HeaderLines', mvnTimestampRow-1);
        if ~isempty(mvnDataRow{1})
            mvnDataSplit = strsplit(mvnDataRow{1}{1});
            startTime = str2num(mvnDataSplit{5}(5:end-1)) / 1000; % to ms
        else
            startTime = 0;
        end
        fclose(fid);
    else
        startTime = 0; % to ms
    end
    
    % --------- left sandal ---------
    % read
    if ~isempty(filepath_san_left)
        data_raw.sandals_left = dlmread(filepath_san_left , ' ');
        
        % time alignment
        data_raw.sandals_left(:, 2) = data_raw.sandals_left(:, 2) - startTime;
        
        % calibrate and save
        data_calib.sandals_left.time = data_raw.sandals_left(:, 2);
        data_calib.sandals_left.data = data_raw.sandals_left(:, 3:end);
        
        % --------- right sandal ---------
        % read
        data_raw.sandals_right = dlmread(filepath_san_right , ' ');
        
        % time alignment
        data_raw.sandals_right(:, 2) = data_raw.sandals_right(:, 2) - startTime;
        
        % calibrate and save
        data_calib.sandals_right.time = data_raw.sandals_right(:, 2);
        data_calib.sandals_right.data = data_raw.sandals_right(:, 3:end);
    else
        data_calib.sandals_left.time = [];
        data_calib.sandals_left.data = [];
        data_calib.sandals_right.time = [];
        data_calib.sandals_right.data = [];
    end
    
    % --------- mocap ---------
    % read
    if ~isempty(filepath_mocap)
        data_raw.mocap = readTrc(filepath_mocap);
        
        % calibrate and save
        data_calib.mocap.time = data_raw.mocap.data.Time;
        data_calib.mocap.data = data_raw.mocap.data;
    else
        data_calib.mocap.time = [];
        data_calib.mocap.data = [];
    end
    
    % --------- forceplates ---------
    % read
    if ~isempty(filepath_fp)
    fp = loadFp_calibrate(filepath_fp, filepath_fpUnloaded);
    
    % calibrate and save
    data_calib.fp = fp;
    else
       data_calib.fp.time = [];
       data_calib.fp.F1 = [];
       data_calib.fp.F2 = [];
    end
    
    %% plotting data
    h0 = figure('Position', [1.9378e+03 166.6000 1.8536e+03 916.8000]);
    h1 = subplot(221);
    plot(data_calib.sandals_right.time, data_calib.sandals_right.data, '.'); hold on
    title(['sandal right (subject' num2str(currFileSet.subject) ')']);
    
    h2 = subplot(222);
    plot(data_calib.sandals_left.time,  data_calib.sandals_left.data, '.');
    title(['sandal left (' currFileSet.exercise ')']);
    
    h3 = subplot(224);
    plot(data_calib.fp.time, -1*data_calib.fp.F1, '.');
    title('fp left');
    
    h4 = subplot(223);
    plot(data_calib.fp.time, -1*data_calib.fp.F2, '.');
    title('fp right');
    
    linkaxes([h1 h2 h3 h4], 'x');
    
    %% save all the contents
    saveas(h0, filepath_output_png);
    saveas(h0, filepath_output_fig);
    
    close(h0);
end


