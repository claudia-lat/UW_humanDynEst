function combined = formatMyoData(feature, ClockWindowed, featureControl)

%     % --- RAW SIGNAL FEATURES ---
%     signaldata = signaldataCrop(signal, featureControl);
% 
%     % --- CALCULATED FEATURES ---
%     featuredata = featuredataCrop(feature, featureControl);
    
    % --- TEMPORAL ---
    [startTimeInd, endTimeInd] = timeCrop(ClockWindowed, featureControl);
    
    combined.data = feature(startTimeInd:endTimeInd, :);
    
%     if ~isempty(signaldata)
%         combined.data = [combined.data signaldata(startTimeInd:endTimeInd, :)];
%     end

    if featureControl.modDate
        dayInMS = 24*60*60*1000; % mod out the date stamp
        ClockWindowed = mod(ClockWindowed, dayInMS);
    end
    
    combined.time = ClockWindowed(startTimeInd:endTimeInd, :);
end

function featuredata = featuredataCrop(feature, featureControl)
    switch featureControl.featureFeatures
        case 0
            % just one dof
            ind1 = [];
            
        case 28
            % just one dof
            ind1 = 1:28;
    end
    
    featuredata = feature(:, ind1);
                  
    % reduce the data magnitude so HMM wouldn't have a problem with it
    featuredata = featuredata * featureControl.featureMutliplier; % the pairwise features are natually much larger
    featuredata = featuredata * featureControl.globalMultiplier;
end

function signaldata = signaldataCrop(signal, featureControl)
    switch featureControl.signalFeatures
        case 0
            ind1 = [];
        case 8
            ind1 = 1:8;
    end

    signaldata = signal(:, ind1);

    signaldata = signaldata * featureControl.globalMultiplier;
end

function  [startTimeInd, endTimeInd] = timeCrop(time, featureControl)
    startTimeInd = 1;
    endTimeInd = length(time);
    
    switch featureControl.timeConstrain
        case 'featureControl'
            % go with the timeconstraints outlined in the feature control
            [startTimeInd, endTimeInd] = timeCrop_featureControl(time, featureControl);
            
        case 'kinematic'
            featureControl.timeStart = featureControl.kinTimeStart;
            featureControl.timeEnd = featureControl.kinTimeEnd;
            
            [startTimeInd, endTimeInd] = timeCrop_featureControl(time, featureControl);
                        
        case 'none'
            % no constraints. don't change the values
    end
    
    % final check for legit values for the time
    if startTimeInd < 1
        startTimeInd = 1;
    end
    
    if endTimeInd > length(time)
        endTimeInd = length(time);
    end
end