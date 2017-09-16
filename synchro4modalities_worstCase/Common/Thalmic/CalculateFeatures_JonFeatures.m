function [Feature, ClockWindowed] = CalculateFeatures_JonFeatures(RawEMG, Clock, selectedFeature, WindowSize, WindowShift, Norm)  

% copying the start of Ali's CalculateFeatures_PerWindow so that we have a
% uniform interface for all the metrics being calculated

[Fs, IndexWindow, ClockWindowed, RawEMG] = thalmicNormalize(Clock, RawEMG, WindowSize, WindowShift, Norm);

%% compute RMS curves (no need for this when features are computed for each moving window separately!)
% RMS =  cell2mat(arrayfun(@(x) arrayfun(@(y) norm(RawEMG(IndexWindow(1,x):...
%     IndexWindow(2,x),y))/sqrt(diff(IndexWindow(:,x))),1:size(RawEMG,2)),...
%     1:length(IndexWindow),'uniformoutput',false)');

% the signal calculation from Ali's old code. reports the same results tho
% Signal = cell2mat(arrayfun(@(y) arrayfun(@(x) norm(Data(IndexWindow(1,x):...
%     IndexWindow(2,x),y))/sqrt(diff(IndexWindow(:,x))),...
%     1:length(IndexWindow))',1:size(Data,2),'uniformoutput',false));
%%
switch selectedFeature
    case {1, 2, 3, 4, 5, 6}
        % Top channels calculated by variance
        % on windowed raw data
        Feature = zeros(size(IndexWindow, 2), 1);
%         [closestVal, closestInd] = findClosestValue(subjTime, subjMyo.emgTimeInterpol);
%         
%         closestInd = closestInd(closestInd < size(subjMyo.emgDataInterpol, 1) - subjMyo.windowSize - 1);

        counter = 0;
        for ind_timesteps = 1:size(IndexWindow, 2)
            startInd = IndexWindow(1, ind_timesteps);
            endInd = IndexWindow(2, ind_timesteps);
            
            currDataRow = abs(RawEMG(startInd:endInd, :));
            emgVar = var(currDataRow);
            [maxVal, maxInd] = max(emgVar);
            emgVar(maxInd) = 0;
            [secondVal, secInd] = max(emgVar);
            
            counter = counter + 1;
            
            switch selectedFeature
                case 1
                    % Ratio of the top two channels at a given
                    % timestep. ratio of variance
                    Feature(counter) = secondVal/maxVal;
                    
                case 2
                    % ratio of mean peak value over
                    % window
                    maxMean = mean(currDataRow(:, maxInd));
                    secMean = mean(currDataRow(:, secInd));
                    Feature(counter) = secMean/maxMean;
                    
                case 3
                    % Angle between the magnitude of the top two
                    % channels at a given timestep.
                    maxMean = mean(currDataRow(:, maxInd));
                    secMean = mean(currDataRow(:, secInd));
                    Feature(counter) = abs(acos(secMean/maxMean));
                    
                case 4
                    % Ratio of peak sizes of the top two channels
                    % under a given window
                    maxMean = max(currDataRow(:, maxInd));
                    secMean = max(currDataRow(:, secInd));
                    Feature(counter) = secMean/maxMean;
                    
                case 5
                    % Peak-to-peak distance of the top two channels
                    % under a given window
                    [maxMean, maxLoc] = max(currDataRow(:, maxInd));
                    [secMean, secLoc] = max(currDataRow(:, secInd));
                    Feature(counter) = (maxLoc-secLoc)/Fs;
                    
                case 6
                    % norm of windowed mean
                    Feature(counter) = norm(mean(currDataRow));
            end
        end
        
    case {7, 8, 9, 10}
end
