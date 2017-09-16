
clc;
clear;
close all;

addpath(genpath('xml_io_tools'));
addpath(genpath('data'));


%% filepaths
filepath_mocap = 'data/2017-09-14_TimeSyncTest/mocap/timesync1.trc';
filepath_fp    = 'data/2017-09-14_TimeSyncTest/mocap/timesync1.anc';

filepath_mvn        = 'data/2017-09-14_TimeSyncTest/xsens/test_claudia-001.mvnx';
filepath_san_left   = 'data/2017-09-14_TimeSyncTest/sandals/trial_left_001/data.log';
filepath_san_right  = 'data/2017-09-14_TimeSyncTest/sandals/trial_right_001/data.log';

%% extracting data

% --------- xsens

if exist ('theStruct.mat')
     load ('theStruct.mat');
else  
    theStruct = xml_read(filepath_mvn);
    save ('theStruct.mat');
end

%TODO
% frameInfo = theStruct(2).Children.Children;
% mvnTime = [];
% mvnPos = [];
% for i = 1:length(frameInfo)
%     currTime = str2num(frameInfo(i).Attributes(2).Value) / 1000;
%     currPos = sscanf(frameInfo(i).Children(9).Children.Data, '%f %f %f')';
%     mvnTime = [mvnTime; currTime];
%     mvnPos =  [mvnPos;  currPos];
% end

% --------- left sandal
data.sandals.left = dlmread(filepath_san_left , ' ');
sandalTime.left   = data.sandals.left(:, 2);
sandalData.left   = data.sandals.left(:, 3);

% --------- right sandal
data.sandals.right = dlmread(filepath_san_right , ' ');
sandalTime.right   = data.sandals.right(:, 2);
sandalData.right   = data.sandals.right(:, 3);

% --------- mocap 
fid = fopen(filepath_mocap);
data.mocap = textscan(fid,'%f %f %f %f %f %f %f %f %f %f %f','HeaderLines',6);
fclose(fid);
mocapTime  = data.mocap{2};
mocapData  = data.mocap{3};

% --------- forceplates 
fid = fopen(filepath_fp);
data.fp = textscan(fid,'%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f','HeaderLines',11);
fclose(fid);
fpTime = data.fp{1};

%% aligning signals

% --------- alignment between sandals TODO

% --------- alignment between sandals and xsens 
% sandalTime.left = sandalTime.left - mvnTime(1);
% mvnTime = mvnTime - mvnTime(1);


%% plotting data

% plot
% figure;
% h1 = subplot(211);
% plot(mvnTime, mvnPos, '.');
% h2 = subplot(212);
% plot(sandalTime, sandalData, '.');
% 
% linkaxes([h1 h2], 'x');