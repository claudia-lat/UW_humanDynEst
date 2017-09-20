
clc;
clear;
close all;

addpath(genpath('xml_io_tools'));
addpath(genpath('data'));


%% filepaths
filepath_mocap = '../data/mocap_sept15/set1_smoothed.trc';
filepath_fp    = '../data/mocap_sept15/set1.anc';

filepath_mvn        = '../data/mvnx_sept15/mvnx/test_claudia-001.mvnx';
filepath_san_left   = '../data/sandals_sept15/trial_left_00001/data.log';
filepath_san_right  = '../data/sandals_sept15/trial_right_00001/data.log';

%% extracting data

% --------- xsens

% if exist ('data.mat')
%      load ('data.mat');
% else  
    data.mvn = xml_read(filepath_mvn);
%     save ('data.mat');
% end

%TODO
% frameInfo = theStruct(2).Children.Children;
mvnTime = [];
mvnPos = [];
for i = 4:length(data.mvn.subject.frames.frame)
    currTime = data.mvn.subject.frames.frame(i).ATTRIBUTE.ms / 1000;
    currPos = data.mvn.subject.frames.frame(i).position;
    mvnTime = [mvnTime; currTime];
    mvnPos =  [mvnPos;  currPos];
end

% --------- left sandal
data.sandals.left = dlmread(filepath_san_left , ' ');
sandalTime.left   = data.sandals.left(:, 2);
sandalData.left   = data.sandals.left(:, 3);

% --------- right sandal
data.sandals.right = dlmread(filepath_san_right , ' ');
sandalTime.right   = data.sandals.right(:, 2);
sandalData.right   = data.sandals.right(:, 3);

% --------- mocap 
scanStr = '%f%f';
for i = 1:80
    scanStr = [scanStr '%f%f%f'];
end

fid = fopen(filepath_mocap);
data.mocap = textscan(fid,scanStr,'HeaderLines',6,'Delimiter','/t');
fclose(fid);
mocapTime  = data.mocap{2};
mocapData  = [data.mocap{3:end}];

% --------- forceplates 
scanStr = '%f';
for i = 1:2
    scanStr = [scanStr '%f%f%f%f%f%f%f%f'];
end

fid = fopen(filepath_fp);
data.fp = textscan(fid,scanStr,'HeaderLines',11);
fclose(fid);
fpTime = data.fp{1};
fpData = [data.fp{2:17}];

%% aligning signals

% --------- alignment between sandals TODO

% --------- alignment between sandals and xsens 
% sandalTime.left = sandalTime.left - mvnTime(1);
% mvnTime = mvnTime - mvnTime(1);


%% plotting data

startTime = mvnTime(1);

figure;
h1 = subplot(221);
plot(mvnTime - startTime, mvnPos, '.');
title('mvn');
h2 = subplot(222);
plot(sandalTime.right - startTime, sandalData.right, '.'); hold on
plot(sandalTime.left - startTime, sandalData.left, '.');
title('sandal right+left');
h3 = subplot(223);
plot(mocapTime, mocapData, '.');
title('mocap');
h4 = subplot(224);
plot(fpTime, fpData, '.');
title('fp');
linkaxes([h1 h2 h3 h4], 'x');