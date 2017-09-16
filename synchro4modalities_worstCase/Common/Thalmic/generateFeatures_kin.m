function [ekfData, subjmyoTime, featureTracker] = generateFeatures_kin(shapehandKIN, settings)

activeJointVectors = settings.featureArray;

% subjMyo.emgDataInterpol = shapehandKINKIN.emgData;
% subjMyo.emgTimeInterpol = shapehandKINKIN.emgTime;
% subjMyo.windowSize = settings.windowSize;
% subjMyo.windowOverlap = settings.windowOverlap;
% subjMyo.normMethod = settings.normMethod;
% 
% featureNumber = 15;
% [subjmyoSignal, subjmyoTime] = calculateEMGFeatures(subjMyo, featureNumber);

ekfData = [];
featureTracker = [];

subjmyoTime = shapehandKIN.time;

for ind_jointVector = 1:length(activeJointVectors)
    currVector = activeJointVectors(ind_jointVector);
    switch currVector  % kin 15, kin 15 velo, emg norm, emg channels, emg features
        case 1
            % base 1dof joints (5)
            ind0 = 6;
            ind1 = 6;
            ind2 = [];
            ind3 = [];
            
            dataToAugment = shapehandDataReparse(shapehandKIN, ind0, ind1, ind2, ind3);
            
        case 2
            % extended joints (10)
            ind0 = [];
            ind1 = [];
            ind2 = 6;
            ind3 = 6;
            
            dataToAugment = shapehandDataReparse(shapehandKIN, ind0, ind1, ind2, ind3);
            
        case 3
            % base 2dof joints (10)
            ind0 = 4:5;
            ind1 = 4:5;
            ind2 = [];
            ind3 = [];
            
            dataToAugment = shapehandDataReparse(shapehandKIN, ind0, ind1, ind2, ind3);
            
        case 4
            % base 1dof joints (5) velo
            ind0 = 6;
            ind1 = 6;
            ind2 = [];
            ind3 = [];
            
            dataToStart = shapehandDataReparse(shapehandKIN, ind0, ind1, ind2, ind3);
            dataToAugment = [zeros(1, size(dataToStart, 2)); diff(dataToStart)];
            
        case 5
            % extended joints (10) velo
            ind0 = [];
            ind1 = [];
            ind2 = 6;
            ind3 = 6;
            
            dataToStart = shapehandDataReparse(shapehandKIN, ind0, ind1, ind2, ind3);
            dataToAugment = [zeros(1, size(dataToStart, 2)); diff(dataToStart)];
            
        case 6
            % base 2dof joints (10) velo
            ind0 = 4:5;
            ind1 = 4:5;
            ind2 = [];
            ind3 = [];
            
            dataToStart = shapehandDataReparse(shapehandKIN, ind0, ind1, ind2, ind3);
            dataToAugment = [zeros(1, size(dataToStart, 2)); diff(dataToStart)];
            
        case 7
             dataToAugment = shapehandKIN.joint1;
             
        case 8
            dataToStart = shapehandKIN.joint1;
            dataToAugment = [zeros(1, size(dataToStart, 2)); diff(dataToStart)];
            
        otherwise
            dataToAugment = zeros(size(subjmyoTime));
            
    end
    
    % based on the time, interpolate the values inside,
%     dataToAugmentInterpol = interpolatePadTime(subjmyoTime, timeToAugment, dataToAugment);
    % then pad the values outside
    
    %                     jointVectorInd{ind_jointVector} = size(ekfData, 2)+1:size(ekfData, 2)+size(dataToAugment, 2);

    
    if ~isempty(dataToAugment)
%         dataToAugment =  (pi/180) * dataToAugment; % convert to rad
        
        ekfData = [ekfData dataToAugment];
        featureTracker = [featureTracker ones(1, size(dataToAugment, 2)) * currVector];
    end
end

end

function data = shapehandDataReparse(shapehandKIN, ind0, ind1, ind2, ind3)
    data = [shapehandKIN.finger_00(:, ind0) shapehandKIN.finger_01(:, ind2) shapehandKIN.finger_02(:, ind3) ...
        shapehandKIN.finger_10(:, ind1) shapehandKIN.finger_11(:, ind2) shapehandKIN.finger_12(:, ind3) ...
        shapehandKIN.finger_20(:, ind1) shapehandKIN.finger_21(:, ind2) shapehandKIN.finger_22(:, ind3) ...
        shapehandKIN.finger_30(:, ind1) shapehandKIN.finger_31(:, ind2) shapehandKIN.finger_32(:, ind3) ...
        shapehandKIN.finger_40(:, ind1) shapehandKIN.finger_41(:, ind2) shapehandKIN.finger_42(:, ind3)];
end
