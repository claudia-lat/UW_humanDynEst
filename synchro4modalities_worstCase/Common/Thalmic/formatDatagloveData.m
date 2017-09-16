function combined = formatDatagloveData(shapehandData, time, featureControl)  

%     %  ---- SHAPEHAND ----
%     shapehanddata = shapehandCrop(shapehand, featureControl); % the standard one
%     
%     % --- CORTEX ---
%     cortexdata = cortexdataCrop(cortex, featureControl);
    
%     % --- TEMPORAL ---
%     featureControl.shapehandFeatures = 14; % for normalization and variance analysis
%     shapehanddataNorm = shapehandCrop(shapehand, featureControl);

%     time = time / 1000;
    
    [startTimeInd, endTimeInd] = timeCrop(time, [], featureControl);

    % output
    combined.data = shapehandData(startTimeInd:endTimeInd, :);
    
%     if ~isempty(cortexdata)
%         combined.data = [combined.data cortexdata(startTimeInd:endTimeInd, :)];
%     end
    
    combined.data = unwrap(combined.data);    
    
    if featureControl.modDate
        dayInMS = 24*60*60*1000; % mod out the date stamp
        time = mod(time, dayInMS);
    end
    
    combined.time = time(startTimeInd:endTimeInd, :);
    
    if featureControl.startAtZero
        combined.data = combined.data - repmat(combined.data(1, :), size(combined.data, 1), 1);
    end
end

function shapehanddata = shapehandCrop(shapehand, featureControl)

   switch featureControl.shapehandFeatures
        case 0
            % just one dof
            ind0 = [];
            ind1 = [];
            ind2 = [];
            ind3 = [];
            
        case 3
            % thumb only
            ind0 = 4:6;
            ind1 = 6;
            ind2 = [];
            ind3 = [];
            
        case 5
            % just one dof
            ind0 = [];
            ind1 = [];
            ind2 = 6;
            ind3 = [];
            
        case 14
            ind0 = [];
            ind1 = 6; 
            ind2 = 6;
            ind3 = 6;
            
        case 15
            ind0 = 6;
            ind1 = 6; 
            ind2 = 6;
            ind3 = 6;
            
        case 25
            % all dofs
            ind0 = 4:6;
            ind1 = 4:6;
            ind2 = 6;
            ind3 = 6;
    end
    
%     shapehanddata = [shapehand.finger_00(:, ind1) shapehand.finger_01(:, ind2) shapehand.finger_02(:, ind3) ...
%                       shapehand.finger_10(:, ind1) shapehand.finger_11(:, ind2) shapehand.finger_12(:, ind3) ...
%                       shapehand.finger_20(:, ind1) shapehand.finger_21(:, ind2) shapehand.finger_22(:, ind3) ...
%                       shapehand.finger_30(:, ind1) shapehand.finger_31(:, ind2) shapehand.finger_32(:, ind3) ...
%                       shapehand.finger_40(:, ind1) shapehand.finger_41(:, ind2) shapehand.finger_42(:, ind3)];

    shapehanddata = [shapehand.finger_00(:, ind0) shapehand.finger_01(:, ind2) shapehand.finger_02(:, ind3) ...
                      shapehand.finger_10(:, ind1) shapehand.finger_11(:, ind2) shapehand.finger_12(:, ind3) ...
                      shapehand.finger_20(:, ind1) shapehand.finger_21(:, ind2) shapehand.finger_22(:, ind3) ...
                      shapehand.finger_30(:, ind1) shapehand.finger_31(:, ind2) shapehand.finger_32(:, ind3) ...
                      shapehand.finger_40(:, ind1) shapehand.finger_41(:, ind2) shapehand.finger_42(:, ind3)];
                  
    % reduce the data magnitude so HMM wouldn't have a problem with it
    shapehanddata = (pi/180) * (shapehanddata); % convert to rad
    shapehanddata = shapehanddata * featureControl.globalMultiplier;
    shapehanddata = shapehanddata * featureControl.subjNormalizeFactor;
end

function cortexdata = cortexdataCrop(cortex, featureControl)
    switch featureControl.cortexFeatures 
        case 0
            cortexdata = [];
        case 1
            cortexdata = [cortex.joint1];
        case 3
            cortexdata = [cortex.joint1 cortex.joint2 cortex.joint3];
    end

    cortexdata = (pi/180) * cortexdata;
    cortexdata = cortexdata * featureControl.globalMultiplier;
    cortexdata = cortexdata * featureControl.subjNormalizeFactor;
end

function [startTimeInd, endTimeInd] = timeCrop(time, shapehanddataNorm, featureControl)

    startTimeInd = 1;
    endTimeInd = length(time);
    
    switch featureControl.timeConstrain
        case 'featureControl'
            % go with the timeconstraints outlined in the feature control
            [startTimeInd, endTimeInd] = timeCrop_featureControl(time, featureControl);
            
        case 'variance'
            % go with a variance approach
            [startTimeInd, endTimeInd] = timecrop_varianceShapehand(time, shapehanddataNorm, featureControl);
            
        case 'hybrid'
            % figure out the fixed constraint first
            [startTimeIndFixed, endTimeIndFixed] = timeCrop_featureControl(time, featureControl);
            
            % then see if we can top that with the variance
            featureControlTime = time(startTimeIndFixed:endTimeIndFixed);
            featureControlData = shapehanddataNorm(startTimeIndFixed:endTimeIndFixed, :);
            [startTimeIndVar, endTimeIndVar] = timecrop_varianceShapehand(featureControlTime, featureControlData, featureControl);
            
            % now we need to find the original indices from the original
            % array, after we modified it
            [~, startTimeInd] = findClosestValue(featureControlTime(startTimeIndVar), time);
            [~, endTimeInd] = findClosestValue(featureControlTime(endTimeIndVar), time);
        
        case 'none'
            % no constraints. don't change the values
    end
    
    if 0
        figure;
        plot(shapehanddataNorm);
        hold on
        ylimVal = ylim;
        plot([startTimeInd startTimeInd], [-10 10], 'b');
        plot([endTimeInd endTimeInd], [-10 10], 'b');
        ylim(ylimVal);
    end
    
    % final check for legit values for the time
    if startTimeInd < 1
        startTimeInd = 1;
    end
    
    if endTimeInd > length(time)
        endTimeInd = length(time);
    end
end