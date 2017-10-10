clc;
clear;
close all;

addpath(genpath('xml_io_tools'));
addpath(genpath('mocap_tools'));

%% settings
filepath_base  = 'D:/aslab/data/Fullbody_IIT_2017/';
filepath_subject = 'Pilot00/';
filepath_unloadefp = 'unloaded_fp1.anc';

filepath_index = [filepath_base '/' filepath_subject '/filelist.csv'];

%% load filelist
scanStr = '%s%s%s%s%s%s%s';
fid = fopen(filepath_index);
filelist = textscan(fid,scanStr,'HeaderLines',1,'Delimiter',',');
fclose(fid);

for ind_files = 1:size(filelist{1})
    filepath_mocap = [filepath_base filepath_subject filelist{1}{ind_files}];
    filepath_fp    = [filepath_base filepath_subject filelist{2}{ind_files}];

    filepath_mvn        = [filepath_base filepath_subject filelist{3}{ind_files}];
    filepath_san_left   = [filepath_base filepath_subject filelist{4}{ind_files}];
    filepath_san_right  = [filepath_base filepath_subject filelist{5}{ind_files}];

    filepath_output     = [filepath_base filepath_subject filelist{6}{ind_files}];
    filepath_output_calibmat  = [filepath_output '_calib.mat'];
    filepath_output_fig       = [filepath_output '.fig'];
    
    %% extracting data and aligning
    % --------- xsens ---------
    % read 
    data_raw.mvn = xml_read(filepath_mvn);
    
    % time alignment
    startTime = data_raw.mvn.subject.frames.frame(4).ATTRIBUTE.ms / 1000;
    
    % calibrate and save
    mvnTime = [];
    mvnPos = [];
    for ind_data = 4:length(data_raw.mvn.subject.frames.frame)
        currTime = (data_raw.mvn.subject.frames.frame(ind_data).ATTRIBUTE.ms / 1000) - startTime;
        currPos = data_raw.mvn.subject.frames.frame(ind_data).position;
        mvnTime = [mvnTime; currTime];
        mvnPos =  [mvnPos;  currPos];
    end
    
    data_calib.mvn.time = mvnTime;
    data_calib.mvn.position = mvnPos;
    
    % --------- left sandal ---------
    % read
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
    
    % --------- mocap ---------
    % read
    data_raw.mocap = readTrc(filepath_mocap);
    
    % calibrate and save
    data_calib.mocap.time = data_raw.mocap.data.Time;
    data_calib.mocap.data = data_raw.mocap.data;
    
    % --------- forceplates ---------
     % read
    fp = loadFp_calibrate(filepath_fp, []);
    
    % calibrate and save
    data_calib.fp = fp;
    
    %% plotting data
    h0 = figure;
    h1 = subplot(221);
    plot(data_calib.mvn.time, data_calib.mvn.position, '.');
    title('mvn');

    h2 = subplot(222);
    plot(data_calib.sandals_right.time, data_calib.sandals_right.data, '.'); hold on
    plot(data_calib.sandals_left.time,  data_calib.sandals_left.data, '.');
    title('sandal right+left');

    h3 = subplot(223);
    plot(data_calib.mocap.time, data_calib.mocap.data.EL_LAT, '.');
    title('mocap');

    h4 = subplot(224);
    plot(data_calib.fp.time, data_calib.fp.F1, '.');
    title('fp [N]');
    linkaxes([h1 h2 h3 h4], 'x');
    
    %% save all the contents
    [pathstr,name,ext] = fileparts(filepath_mat_output);
    
    if ~exist(pathstr, 'dir')
        mkdir(pathstr)
    end

    save(filepath_output_calibmat, 'data_calib');
    saveas(h0, filepath_output_fig);
end


