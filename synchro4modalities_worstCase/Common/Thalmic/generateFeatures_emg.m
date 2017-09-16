function [ekfData, subjmyoTime, featureTracker] = generateFeatures_emg(myoEMG, settings)

activeJointVectors = settings.featureArray;

subjMyo.emgDataInterpol = myoEMG.emgData;
subjMyo.emgTimeInterpol = myoEMG.emgTime;
subjMyo.windowSize = settings.windowSize;
subjMyo.windowOverlap = settings.windowOverlap;
subjMyo.normMethod = settings.normMethod;

featureNumber = 15;
[subjmyoSignal, subjmyoTime] = calculateEMGFeatures(subjMyo, featureNumber);

ekfData = [];
featureTracker = [];

for ind_jointVector = 1:length(activeJointVectors)
    currVector = activeJointVectors(ind_jointVector);
    switch currVector  % kin 15, kin 15 velo, emg norm, emg channels, emg features
        case 1
            % raw EMG - downsample
            dataToAugment = spline(subjMyo.emgTimeInterpol', subjMyo.emgDataInterpol', subjmyoTime')';
            timeToAugment = subjmyoTime;
            
        case 2
            % rms EMG
            dataToAugment = subjmyoSignal;
            timeToAugment = subjmyoTime;
            
        case 3
            % rms pairwise dot product
            featureNumber = 16;
            [dataToAugment, timeToAugment] = calculateEMGFeatures(subjMyo, featureNumber, subjmyoTime);
            
        case {4, 5, 6, 7, 8, 9}
            % Jon features
            % 1 Raw EMG, top two calc by var, Ratio of top two var values
            % 2 Raw EMG, top two calc by var, ratio of mean peak value over window
            % 3 Raw EMG, top two calc by var, angle btwn magnitude of top two
            % 4 Raw EMG, top two calc by var,  ratio of peak within window
            % 5 Raw EMG, top two calc by var, peak to peak distance
            % 6 Raw EMG, top two calc by var,  norm of windowed mean
            featureNumber = currVector - 3;
            [dataToAugment, timeToAugment] = calculateEMGFeatures_Jon(subjMyo, featureNumber, subjmyoTime);            
            
        case {10, 11}
            % select the top two myoSignal channels at a
            % given timestep and use the ratio of these two
            % signals. top calculated by peak
            signalDerived = zeros(1, size(subjmyoSignal, 1));
            for ind_timesteps = 1:size(subjmyoSignal, 1)
                currDataRow = subjmyoSignal(ind_timesteps, :);
                [maxVal, maxInd] = max(currDataRow);
                currDataRow(maxInd) = 0;
                [secondVal, secInd] = max(currDataRow);
                
                switch activeJointVectors(ind_jointVector)
                    case 10
                        % non-windowed magnitude
                        signalDerived(ind_timesteps) = secondVal/maxVal;
                        
                    case 11
                        % angle of non-windowed mag
                        signalDerived(ind_timesteps) = abs(acos(secondVal/maxVal));
                end
            end
            
            dataToAugment = signalDerived';
            timeToAugment = subjmyoTime;
            
%         case {12, 13}
%             % select the top two myoSignal channels at a
%             % given timestep and use the ratio of these two
%             % signals. top calculated by peak
%             [~, IndexWindow, ClockWindowed, ~] = thalmicNormalize(subjMyo.emgTimeInterpol, ...
%                 subjMyo.emgDataInterpol, subjMyo.windowSize, subjMyo.windowOverlap, subjMyo.normMethod);
%             
%             signalDerived = zeros(size(IndexWindow, 2), 1);
%             
%             for ind_timesteps = 1:size(IndexWindow, 2)
%                 currDataRow = subjmyoSignal(ind_timesteps, :);
%                 [maxVal, maxInd] = max(currDataRow);
%                 currDataRow(maxInd) = 0;
%                 [secondVal, secInd] = max(currDataRow);
%                 
%                 slidingWinInd = IndexWindow(1, ind_timesteps):IndexWindow(2, ind_timesteps);
%                 
%                 switch activeJointVectors(ind_jointVector)
%                     case 12
%                         % windowed variance
%                         maxVar = var(subjmyoSignal(slidingWinInd, maxInd));
%                         secVar = var(subjmyoSignal(slidingWinInd, secInd));
%                         signalDerived(ind_timesteps) = secVar/maxVar;
%                         
%                         
%                     case 13
%                         % windowed peak to peak time
%                         samplingRate = 1/mean(diff(subjmyoTime));
%                         
%                         maxVar = subjmyoSignal(slidingWinInd, maxInd);
%                         secVar = subjmyoSignal(slidingWinInd, secInd);
%                         
%                         [maxMean, maxLoc] = max(maxVar);
%                         [secMean, secLoc] = max(secVar);
%                         signalDerived(ind_timesteps) = (maxLoc-secLoc)/samplingRate;
%                 end
%                 
%             end
%             
%             dataToAugment = signalDerived;
%             timeToAugment = subjmyoTime(IndexWindow(2, :));
            
        case 12
            % norm of the rms emg signal
            normSignal = zeros(1, size(subjmyoSignal, 1));
            for ind_normizer = 1:size(subjmyoSignal, 1)
                normSignal(ind_normizer) = norm(subjmyoSignal(ind_normizer, :));
            end
            dataToAugment = normSignal';
            timeToAugment = subjmyoTime;
            
        case 13
            featureNumber = 17;
            [dataToAugment, timeToAugment] = calculateEMGFeatures(subjMyo, featureNumber, subjmyoTime);
                        
        case {21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34}
            % ali's features
            featureNumber = currVector - 20;
            [dataToAugment, timeToAugment]  = calculateEMGFeatures(subjMyo, featureNumber, subjmyoTime);
            
        otherwise
            dataToAugment = zeros(size(subjmyoTime));
            
    end
    
    % based on the time, interpolate the values inside,
%     dataToAugmentInterpol = interpolatePadTime(subjmyoTime, timeToAugment, dataToAugment);
    % then pad the values outside
    
    %                     jointVectorInd{ind_jointVector} = size(ekfData, 2)+1:size(ekfData, 2)+size(dataToAugment, 2);

    
    if ~isempty(dataToAugment)
        ekfData = [ekfData dataToAugment];
        featureTracker = [featureTracker ones(size(dataToAugment)) * currVector];
    end
end

