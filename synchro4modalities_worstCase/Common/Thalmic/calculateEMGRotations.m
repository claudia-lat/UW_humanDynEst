%% load EMG data from subject as template
sourcePath = 'D:\MyDocument\MotionData\Thalmic_2014-12\';
targetSubject = 'S1';
targetMotion = 'POut_1';
targetPathMyo = [sourcePath '\' targetSubject '\' targetMotion '.mat'];
[myoEMG, myoEMGOriginal] = loadMyoData(targetPathMyo);

%% determine the 'shape' of the POut profile
% [Feature, Clock] = Calculate_Features(myoEMGOriginal);
absEMG = abs(myoEMG.emgData);
[output, zf] = filter_butterworth_function(absEMG);

% find the norm of the envelope
normArray = zeros(1, size(output, 1));
for x = 1:size(output, 1)
    normArray(x) = norm(output(x, :));
end
[maxVal, maxInd] = max(normArray); % find the timestep with the largest norm

%% select the rotation amount
% want the maximum peak ampitude over node 1
rotIndArray = 0:0.5:360;
smallSurveyCounter = 0;
smallShiftSurvey = zeros(1, length(rotIndArray));
for rotInd = rotIndArray
    smallShiftEMGTemp = emgRotate(output(maxInd, :), rotInd);
    smallSurveyCounter = smallSurveyCounter + 1;
    smallShiftSurvey(smallSurveyCounter) = smallShiftEMGTemp(1);
end
[rotVal, rotInd] = max(smallShiftSurvey); % TODO
rotAmt = rotIndArray(rotInd);

%% rotate it so it's straight up as the peak
smallShiftEMG = emgRotate(output, rotAmt);

% % %% apply the loaded POut profile to other subjects' POut, and generate a rotational matrix
% % 
% % sourcePath = 'D:\MyDocument\MotionData\Thalmic_2014-12\';
% % targetSubject = 'S2';
% % targetMotion = 'POut_1';
% % targetPathMyo = [sourcePath '\' targetSubject '\' targetMotion '.mat'];
% % myoEMG = loadMyoData(targetPathMyo);
% % 
%% apply to other motions in the subject's data