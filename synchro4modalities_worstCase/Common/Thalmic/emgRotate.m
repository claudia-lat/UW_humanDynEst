function smallShiftEMG = emgRotate(featureEMG, rotationAmount)
% rotate the EMG data by 'rotationAmount'

% featureEMG = output;
% 
% rotationAmount = 90+45+45/4; % clockwise
totalNodeCount = size(featureEMG, 2);
nodeIncrement = 360/totalNodeCount;

% rotate large increments
largeShift = floor(rotationAmount / nodeIncrement); 
largeMod = rem(rotationAmount, nodeIncrement);

largeShiftEMG = zeros(size(featureEMG));

% rotating it clockwise, so taking the current one from a ccw direction
for currNode = 1:totalNodeCount
    sourceNode = currNode - largeShift;
    if sourceNode < 1
        sourceNode = sourceNode + totalNodeCount;
    end
    
    largeShiftEMG(:, currNode) = featureEMG(:, sourceNode);
end

% rotate small increments
for currNode = 1:totalNodeCount
    if largeMod > 0
        % positive, so we take it from previous one
        targetNode = currNode - 1;
        
        if targetNode == 0
            targetNode = totalNodeCount;
        end
    else
        targetNode = currNode + 1;
        
        if targetNode == totalNodeCount + 1;
            targetNode = 1;
        end
    end
    
    % calculate percentages
    selfShiftPercent = 1 - abs(largeMod/nodeIncrement);
    otherShiftPercent = 1 - selfShiftPercent;
    
    smallShiftEMG(:, currNode) = selfShiftPercent*largeShiftEMG(:, currNode) + ...
        otherShiftPercent*largeShiftEMG(:, targetNode);
end