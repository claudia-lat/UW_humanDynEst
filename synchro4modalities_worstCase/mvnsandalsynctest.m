filepath_mvn = 'test_claudia-0042_noSandals_rec.mvnx';
filepath_san = 'data.log';

theStruct = parseXML(filepath_mvn);
frameInfo = theStruct(2).Children.Children;

% mvnTime = [];
% mvnPos = [];
% for i = 1:length(frameInfo)
%     currTime = str2num(frameInfo(i).Attributes(2).Value) / 1000;
%     currPos = sscanf(frameInfo(i).Children(9).Children.Data, '%f %f %f')';
%     mvnTime = [mvnTime; currTime];
%     mvnPos =  [mvnPos;  currPos];
% end
% 
% data = dlmread(filepath_san, ' ');
% sandalTime = data(:, 2);
% sandalData = data(:, 3);
% 
% sandalTime = sandalTime - mvnTime(1);
% mvnTime = mvnTime - mvnTime(1);
% 
% figure;
% h1 = subplot(211);
% plot(mvnTime, mvnPos, '.');
% h2 = subplot(212);
% plot(sandalTime, sandalData, '.');
% 
% linkaxes([h1 h2], 'x');