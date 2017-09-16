function [rotAmt, maxAmt] = loadMyoRotation(sourcePath, targetSubject)
    % pout is the sync motion
    
    rotAmtArray = [];
    maxAmtArray = [];
    for i = 1:5
        targetPathMyo1 = fullfile(sourcePath, targetSubject, ...
            ['pout_' num2str(i) '_emg.mat']);
        
        targetPathMyo2 = fullfile(sourcePath, ['Subject' num2str(targetSubject)], ...
            'Session1', ['PDDM_OUT' num2str(i)], 'Myo', 'emg.mat');

        targetPathMyo3 = fullfile(sourcePath, targetSubject, ...
            'Session1', ['PDDM_OUT' num2str(i)], 'Myo', 'emg.mat');
    
        if exist(targetPathMyo1, 'file')
            targetPathMyo = targetPathMyo1;
        elseif exist(targetPathMyo2, 'file')
            targetPathMyo = targetPathMyo2;
        elseif exist(targetPathMyo3, 'file')
            targetPathMyo = targetPathMyo3;
        else
            continue
        end
        
        myoEMGRot = loadMyoData(targetPathMyo);

        [~, rotAmt] = calculateEMGRotationsFct(myoEMGRot);
        rotAmtArray = [rotAmtArray rotAmt];

        maxVal = max(max(abs(myoEMGRot.emgData)));
        maxAmtArray = [maxAmtArray maxVal];
    end
    
%     rotAmtArray
    rotAmt = mode(rotAmtArray);
    maxAmt = mean(maxAmtArray);

