function [smallShiftEMG, rotAmt] = calculateEMGRotationsFct(myoEMG)
    % calculate based on abs and lpf
%     absEMG = abs(myoEMG.emgData);
%     [featureEMG, zf] = filter_butterworth_function(absEMG);
    
    % how to determine peak?
    peakDet = 'norm'; % max norm
    
    % calculate based on RMS
    [~, featureEMG, ~] = Calculate_Features(myoEMG, 1, 30, 10); 
    
    % find the norm of the envelope
    switch peakDet
        case 'norm'
            normArray = normVector(featureEMG);
            [maxVal, maxInd] = max(normArray); % find the timestep with the largest norm
        case 'max'
            [maxVal, maxInd1] = max(featureEMG, [], 2);
            [maxVal, maxInd] = max(featureEMG(:, maxInd1(1))); % find the timestep with the largest norm
    end

    %% select the rotation amount
    % want the maximum peak ampitude over node 1
    rotIndArray = 0:0.5:360;
    smallSurveyCounter = 0;
    smallShiftSurvey = zeros(1, length(rotIndArray));
    targetEMGToMax = featureEMG(maxInd, :);
    for rotInd = rotIndArray
        smallShiftEMGTemp = emgRotate(targetEMGToMax, rotInd);
        smallSurveyCounter = smallSurveyCounter + 1;
        smallShiftSurvey(smallSurveyCounter) = smallShiftEMGTemp(1);
    end
    [rotVal, rotInd] = max(smallShiftSurvey); % TODO
    rotAmt = rotIndArray(rotInd);
    
    % figure; plot(rotIndArray, smallShiftSurvey);

    %% rotate it so it's straight up as the peak
    smallShiftEMG = emgRotate(featureEMG, rotAmt);