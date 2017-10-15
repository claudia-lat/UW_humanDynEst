clc;
clear;
close all;

addpath(genpath('xml_io_tools'));
addpath(genpath('mocap_tools'));

%% settings
filepath_base  = 'D:/aslab/data/Fullbody_IIT_2017/';
filepath_subject{1} = 'Pilot00/';
filepath_subject{2} = 'Subject01/';
filepath_subject{3} = 'Subject02/';
filepath_subject{4} = 'Subject03/';
filepath_subject{5} = 'Subject04/';
filepath_unloadefp = 'unloaded_fp1.anc';

overwrite = 0;

filepath_index = [filepath_base '/' filepath_subject '/filelist.csv'];

%% load filelist and iterate
scanStr = '%s%s%s%s%s%s%s';
fid = fopen(filepath_index);
filelist = textscan(fid,scanStr,'HeaderLines',1,'Delimiter',',');
fclose(fid);


synchro_dataparse;
synchro_plot;