function [shapehand, cortex] = loadDatagloveData(targetPath)
    % load shapehand kinematic information from cortex SDK output
    % 1:3 is offset
    % 4:6 is rot 
    % 7 is bone length
    
    % pull out the date information 
    tempDir = dir(targetPath);
    tempDate = datevec(tempDir.datenum);
    tempDate(4:6) = [0 0 0];
    shimmerParam.date = datenum(tempDate);

    % load the cortex SDK data
    cortexData = parseCortexCSV(targetPath, shimmerParam, 3, 3);
    
    % interpolate the time array
    cortexTimeOrig = cortexData.SystemMSTimeStamp;
    cortexData.SystemMSTimeStamp = linspace(cortexTimeOrig(1), cortexTimeOrig(end), length(cortexTimeOrig))';
    
    % mod out the date information
    cortexData.SystemMSTimeStamp = cortexData.SystemMSTimeStamp;
    
    if isfield(cortexData, 'Cyberglove1_R_Bip01_R_Hand__1')
        gloveName = 'Cyberglove1_R';    
    elseif isfield(cortexData, 'Shapehand1_R_Bip01_R_Hand__1')
        gloveName = 'Shapehand1_R';
    end
    
    if isfield(cortexData, 'Upperbody_Shoulder__x')
        modelName = 'Upperbody';
    elseif isfield(cortexData, 'UpperBody_Shoulder__x')
        modelName = 'UpperBody';
    end

    % combine the related vectors together, for the shapehand
    shapehand.frame = cortexData.Frame;
    shapehand.time = cortexData.SystemMSTimeStamp; % shift time into seconds
    shapehand.hand = combineArray(cortexData, [gloveName '_Bip01_R_Hand__'], 1:7); 
    shapehand.finger_00 = combineArray(cortexData, [gloveName '_Bip01_R_Finger0__'], 1:7);
    shapehand.finger_01 = combineArray(cortexData, [gloveName '_Bip01_R_Finger01__'], 1:7); 
    shapehand.finger_02 = combineArray(cortexData, [gloveName '_Bip01_R_Finger02__'], 1:7);
    shapehand.finger_10 = combineArray(cortexData, [gloveName '_Bip01_R_Finger1__'], 1:7);
    shapehand.finger_11 = combineArray(cortexData, [gloveName '_Bip01_R_Finger11__'], 1:7);
    shapehand.finger_12 = combineArray(cortexData, [gloveName '_Bip01_R_Finger12__'], 1:7);
    shapehand.finger_20 = combineArray(cortexData, [gloveName '_Bip01_R_Finger2__'], 1:7);
    shapehand.finger_21 = combineArray(cortexData, [gloveName '_Bip01_R_Finger21__'], 1:7);
    shapehand.finger_22 = combineArray(cortexData, [gloveName '_Bip01_R_Finger22__'], 1:7);
    shapehand.finger_30 = combineArray(cortexData, [gloveName '_Bip01_R_Finger3__'], 1:7);
    shapehand.finger_31 = combineArray(cortexData, [gloveName '_Bip01_R_Finger31__'], 1:7);
    shapehand.finger_32 = combineArray(cortexData, [gloveName '_Bip01_R_Finger32__'], 1:7);
    shapehand.finger_40 = combineArray(cortexData, [gloveName '_Bip01_R_Finger4__'], 1:7);
    shapehand.finger_41 = combineArray(cortexData, [gloveName '_Bip01_R_Finger41__'], 1:7);
    shapehand.finger_42 = combineArray(cortexData, [gloveName '_Bip01_R_Finger42__'], 1:7);
                  
    shapehand.gen = combineArray(cortexData, [gloveName '_gencoord'], 0:19);
    
    % combine the related vectors together, for the marker data
    cortex.frame = cortexData.Frame;
    cortex.time = cortexData.SystemMSTimeStamp; % shift time into seconds
    
    if isfield(cortexData, [modelName '_Wrist_L__x'])
        nameL = '_L__';
        nameR = '_R__';
        
    elseif isfield(cortexData, [modelName '_Wrist1__x'])
        nameL = '1__';
        nameR = '2__';
    end
    
%     cortex.shoulder = combineArray(cortexData, [modelName '_Shoulder__'], {'x', 'y', 'z'});
%     cortex.back = combineArray(cortexData, [modelName '_Back__'], {'x', 'y', 'z'});
    cortex.wrist_lat = interpolateCortexData(cortex.time, combineArray(cortexData, [modelName '_Wrist' nameL], {'x', 'y', 'z'}));
    cortex.wrist_rad = interpolateCortexData(cortex.time, combineArray(cortexData, [modelName '_Wrist' nameR], {'x', 'y', 'z'}));
    cortex.elbow_lat = interpolateCortexData(cortex.time, combineArray(cortexData, [modelName '_Elbow' nameL], {'x', 'y', 'z'}));
    cortex.elbow_rad = interpolateCortexData(cortex.time, combineArray(cortexData, [modelName '_Elbow' nameR], {'x', 'y', 'z'}));
%     cortex.hand = combineArray(cortexData, [modelName '_Hand__'], {'x', 'y', 'z'});
    cortex.finger = interpolateCortexData(cortex.time, combineArray(cortexData, [modelName '_Finger__'], {'x', 'y', 'z'}));
    
    % combine the wrist data
    cortex.wrist = [mean([cortex.wrist_lat(:, 1) cortex.wrist_rad(:, 1)], 2) ...
        mean([cortex.wrist_lat(:, 2) cortex.wrist_rad(:, 2)], 2) ...
        mean([cortex.wrist_lat(:, 3) cortex.wrist_rad(:, 3)], 2)];
    
    cortex.elbow = [mean([cortex.elbow_lat(:, 1) cortex.elbow_rad(:, 1)], 2) ...
        mean([cortex.elbow_lat(:, 2) cortex.elbow_rad(:, 2)], 2) ...
        mean([cortex.elbow_lat(:, 3) cortex.elbow_rad(:, 3)], 2)];
    
    % calculate simple angles between finger and wrist
    if isfield(cortex, 'finger') && ~isempty(cortex.finger)
        cortex.joint1 = cosineLaw(cortex.elbow(:, 1), cortex.wrist(:, 1), cortex.finger(:, 1));
        cortex.joint2 = cosineLaw(cortex.elbow(:, 2), cortex.wrist(:, 2), cortex.finger(:, 2));
        cortex.joint3 = cosineLaw(cortex.elbow(:, 3), cortex.wrist(:, 3), cortex.finger(:, 3));
    else
        cortex.joint1 = [];
        cortex.joint2 = [];
        cortex.joint3 = [];
    end
end