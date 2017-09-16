function [startTimeInd, endTimeInd] = timecrop_varianceShapehand(time, shapehanddataNorm, featureControl)
    % we can tune how tight of the variance threshold we want
    % to pick by adjusting the following two variances
    indJump = 10; % windowing for mean/var
    histBinCount = 20; % 10 is matlab default
    thresholdBinInd = 1; % how much deviation are we allowing the normalized mean?
    fixedOffset = 25; % safety factor. don't want to cut off too much. 25 = roughly quarter second

    normShapehand = shapehanddataNorm(:, 1) .^ 2;
    for i = 2:size(shapehanddataNorm, 2)
        normShapehand = normShapehand + shapehanddataNorm(:, i) .^ 2;
    end
    normShapehand = normShapehand .^ 0.5;

    % assume that the motion will have two states: resting, or
    % active. look at the means from the edges for resting
    counter = 0;
    slidingMean = zeros(length(time)-indJump, 1);
    for i = 1:length(time)-indJump
        counter = counter + 1;
        %                     slidingInd(counter, 1) = i;
        %                     slidingInd(counter, 2) = i+indJump;
        slidingMean(counter) = mean(normShapehand(i:i+indJump));
        %                     slidingVar(counter) = var(normShapehand(i:i+indJump));
    end

    % obtain the starting rest position
    restingMean = slidingMean(1); % calculating resting mean
    normalizedMean = abs(slidingMean - restingMean);

    % find the nth bin mean (the first bin should be the
    % smallest, since we're using normalized abs mean around
    % the resting value), to use as a threshold, then pull out
    % all the values below this threshold. use the edge of the
    % first cluster as the starting time
    [searchVarVal, diffInd] = findBinThreshold(normalizedMean, histBinCount, thresholdBinInd);

    if isempty(diffInd)
        % they're all below the threshold, so find the last entry in the
        % cluster, and apply the offset
        startTimeInd = length(searchVarVal) - fixedOffset;
    else
        diffIndVal = diffInd(1)-1;
        if diffIndVal == 0
            % the first point is the target
            startTimeInd = searchVarVal(1) - fixedOffset;
        else
            startTimeInd = searchVarVal(diffInd(1)-1) - fixedOffset;
        end
    end

    % now find the ending rest position, and do the same thing
    restingMean = slidingMean(end); % calculating resting mean
    normalizedMean = abs(slidingMean - restingMean);
    [searchVarVal, diffInd] = findBinThreshold(normalizedMean, histBinCount, thresholdBinInd);

    if isempty(diffInd)
        % they're all below the threshold, so find the last entry in the
        % cluster, and apply the offset
        endTimeInd = length(time) - length(searchVarVal) + fixedOffset;
    else
        diffIndVal = diffInd(end)+1;
        if diffIndVal > length(searchVarVal)
            % last value
            endTimeInd = searchVarVal(diffInd(end)) + fixedOffset;
        else
            endTimeInd = searchVarVal(diffInd(end)+1) + fixedOffset;
        end
    end
    
    if startTimeInd < 1
        startTimeInd = 1;
    end
    
    if endTimeInd > length(time)
        endTimeInd = length(time);
    end
    
        %                 % pull out all the mean index locations that are at these
    %                 % thresholds, and is within 1 var away from the resting
    %                 % mean, up to the diff points in the variance
    %                 thresholdMean = mean(binVal(thresholdMeanInd));
    %                 searchVarIndStartCluster = searchVarInd(searchVarInd < searchTarget(1));
    %                 for i = 1:length(searchVarIndStartCluster)
    %                     if normalizedMean(searchVarIndStartCluster(i)) < thresholdMean
    %                         localInd = i;
    %                         startTimeInd = slidingInd(localInd, 1);
    %                     end
    %                 end

    %                 searchVarIndEndCluster = searchVarInd(searchVarInd > searchTarget(end));
    %                 for i = length(searchVarIndEndCluster):-1:1
    %                     if normalizedMean(searchVarIndEndCluster(i)) < thresholdMean
    %                         localInd = searchVarIndEndCluster(i);
    %                         endTimeInd = slidingInd(localInd, 2);
    %                     end
    %                 end
end

function [searchVarVal, diffInd] = findBinThreshold(normalizedMean, histBinCount, thresholdBinInd)
    [~, binVal] = hist(normalizedMean, histBinCount);
    thresholdVar = binVal(thresholdBinInd);
    [searchVarVal, searchVarInd] = find(normalizedMean < thresholdVar);
    [diffVal] = diff(searchVarVal); % is there a jump in the variance? could be after the curve
    diffInd = find(diffVal > 1);
end