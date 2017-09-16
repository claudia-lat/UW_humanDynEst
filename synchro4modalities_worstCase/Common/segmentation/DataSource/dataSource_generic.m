function [jointAngle, jointTime, segmentInfo] = dataSource_generic(dataSettings, baseFolder, jointPath, segPath, motionSet, Ntemplate)
    % load and process Dana's TRO dataset (long)
    % remodified to fit new featurem-hmm format
    % segmentIncludeInd is '1' for include (train using this)
    %                      '0' for meh (don't train, but can test)
    %                     '-1' for blacklist (don't train or test)
    
    %load joint and segment data
    jointData = motionAnalysis_generic_jointFileRead(jointPath, ',');
    segmentData = motionAnalysis_generic_segFileRead(segPath, ','); % though, there is an instance attached to jointPath
    
    % copy out joint names
    jointTime = jointData.joint(:, 1);
    jointDt = mean(diff(jointTime));
    jointAngleData = jointData.joint(:, 2:end);

    segmentInd = segmentData.segmentTime; % segmentTimeOrig segmentData.segmentTimeModified
    segmentLabels = segmentData.segmentName;
    segmentId = segmentData.segmentId;
    
    %     % combine the templates    
    [segmentStart, segmentEnd, segmentName, segmentIncludeInd] = ...
        dataSetTemplate_pointsOnly(jointAngleData, segmentLabels, segmentInd, segmentId, motionSet, Ntemplate, [], 1);

    segmentInfo.timeStart = segmentStart;
    segmentInfo.timeEnd = segmentEnd;
    segmentInfo.segmentName = segmentName;
    segmentInfo.segmentIncludeInd = segmentIncludeInd; 
    segmentInfo.segmentCount = 1:length(segmentInfo.timeStart);
    segmentInfo.use = ones(size(segmentInfo.segmentCount));
     
    segIndSegStart = 1; % start from the first segment
    segIndSegEnd = size(jointAngleData, 1);
    
    jointTime = jointTime(segIndSegStart:segIndSegEnd);
    jointAngle = unwrap(jointAngleData(segIndSegStart:segIndSegEnd, :)); % stripping frame count
    
    if 0 
        h = figure;
        plot(jointTime, jointAngle);
        plotBoxes(h, segmentInfo.timeStart, segmentInfo.timeEnd);
    end
end

function [timeStart, timeEnd, segmentName, includeVector] = dataSetTemplate_pointsOnly(dataset, segmentLabels, segmentInd, segmentId, motionName, templateCount, templateBlacklist, fullSegmentsFlag)
    % pull out the template motion, the last 'templateCount' few

    % BW filter parameters
%     filterFreq = 0.5;
%     filterSample = 25;
%     filterOrder = 5;
    
    % pull out all the motions and identify the timestamps
    [motionLocationsFull, motionIdFull, segmentName] = motionLocator(segmentLabels, segmentId, 'ALLMOTIONS', fullSegmentsFlag);
    
    timeStart = zeros(size(motionLocationsFull, 1), 1);
    timeEnd = zeros(size(motionLocationsFull, 1), 1);
    
    for i = 1:size(motionLocationsFull, 1)
        timeStart(i) = segmentInd(motionLocationsFull(i, 1), 1);
        timeEnd(i)   = segmentInd(motionLocationsFull(i, end), 2);
    end

    includeMatrix = zeros(length(motionLocationsFull), length(motionName));
    for i = 1:length(motionName)
        currMotion = motionName{i};
        [motionLocations, motionId, motionNameArray] = motionLocator(segmentLabels, segmentId, currMotion, fullSegmentsFlag);
        
        if fullSegmentsFlag
            % make sure nothing from the blacklist is included in the template training
            [allowableMotionId, allowableMotionInd] = setdiff(motionId, templateBlacklist);
            allowableMotionLocation = motionLocations(allowableMotionInd, :);
        else                
            % make sure nothing from the blacklist is included in the template training
            [allowableMotionId, allowableMotionInd] = setdiff(motionLocations(:, 1), templateBlacklist);
            allowableMotionLocation = motionLocations(allowableMotionInd, :);
        end

        
        if size(allowableMotionLocation, 1) < templateCount
            fprintf(['DataSource2: Template available less than desired for ' ...
                currMotion, ', have ' num2str(size(allowableMotionLocation, 1)) ' but want ' num2str(templateCount) '\n']);
            templateCountUse = size(allowableMotionLocation, 1);
        else
            templateCountUse = templateCount;
        end
        
        if fullSegmentsFlag
            selectIdInd = allowableMotionId(end-templateCountUse+1:end);
        else
            selectIdInd = allowableMotionLocation(end-templateCountUse+1:end, 1);
        end
        
        includeMatrix(selectIdInd, i) = 1; % NOT ID, the indice of the item itself
    end
    
    includeVector = sum(includeMatrix, 2);
    includeVector = +includeVector;
%     templateTime = cell(1, templateCount);
%     templateDataSet = cell(1, templateCount);
%     segTime = zeros(1, templateCount*2);
%     label = cell(1, templateCount*2);
%     id = zeros(1, templateCount*2);
%     
%     for i = 1:templateCount
%         segStart = segmentInd(motionLocationCount(i, 1), 1); % combine the "up" and "down" motion
%         segEnd = segmentInd(motionLocationCount(i, end), 2);
%         time = (segStart:segEnd)'/frameRate;
%         
%         templateData = unwrap(dataset(segStart:segEnd, dofToUse)); % strip out the frame number, and unwrap angle        
% %         templateData = filter_dualpassBW(templateData, filterFreq, filterSample, filterOrder); % and filter
%         
%         if hmm
%             time = time';
%             templateData = templateData';
%         end
%         
%         templateTime{i} = time;
%         templateDataSet{i} = templateData;
%         
%         doubleInd = (i-1)*2+1:(i)*2;
%         segTime(doubleInd) = time([1 end]);
%         label{doubleInd(1)} = motionName;
%         label{doubleInd(2)} = motionName;
%         id(doubleInd) = [motionNameId motionNameId];
% 
%     end
%     
%     templateStruct.data = templateDataSet;
%     templateStruct.time = templateTime;
%     templateStruct.label = label;
%     templateStruct.id = id;
%     templateStruct.manualSegTime = segTime;
%     templateStruct.count = templateCount;
end

function templateStruct = dataSetTemplate(dataset, segmentInd, segmentLabels, segmentId, motionName, motionNameId, templateCount, frameRate, dofToUse, hmm)
    % pull out the template motion, the last 'templateCount' few

    % BW filter parameters
%     filterFreq = 0.5;
%     filterSample = 25;
%     filterOrder = 5;
    
    [motionLocations, motionId, segmentName] = motionLocator(segmentLabels, segmentId, motionName);
    
    if size(motionLocations, 1) < templateCount
        fprintf(['DataSource2: Template available less than desired for ' ...
            motionName, ', have ' num2str(size(motionLocations, 1)) ' but want ' num2str(templateCount) '\n']);
        templateCount = size(motionLocations, 1);
    end
    
    motionLocationCount = motionLocations(end-templateCount+1:end, :);
    
    templateTime = cell(1, templateCount);
    templateDataSet = cell(1, templateCount);
    segTime = zeros(1, templateCount*2);
    label = cell(1, templateCount*2);
    id = zeros(1, templateCount*2);
    
    for i = 1:templateCount
        segStart = segmentInd(motionLocationCount(i, 1), 1); % combine the "up" and "down" motion
        segEnd = segmentInd(motionLocationCount(i, end), 2);
        time = (segStart:segEnd)'/frameRate;
        
        templateData = unwrap(dataset(segStart:segEnd, dofToUse)); % strip out the frame number, and unwrap angle        
%         templateData = filter_dualpassBW(templateData, filterFreq, filterSample, filterOrder); % and filter
        
        if hmm
            time = time';
            templateData = templateData';
        end
        
        templateTime{i} = time;
        templateDataSet{i} = templateData;
        
        doubleInd = (i-1)*2+1:(i)*2;
        segTime(doubleInd) = time([1 end]);
        label{doubleInd(1)} = motionName;
        label{doubleInd(2)} = motionName;
        id(doubleInd) = [motionNameId motionNameId];

    end
    
    templateStruct.data = templateDataSet;
    templateStruct.time = templateTime;
    templateStruct.label = label;
    templateStruct.id = id;
    templateStruct.manualSegTime = segTime;
    templateStruct.count = templateCount;
end

function [segmentTime, segmentLabel, segmentCount] = dataSetSegmentation(segmentInd, segmentLabels, segmentId, motionName, segmentPassCount, frameRate)
    % pull out the template motion, the last 'templateCount' few

%     % BW filter parameters
%     filterFreq = 0.5;
%     filterSample = 25;
%     filterOrder = 5;
    
    [motionLocations, namedSegmentId, segmentName] = motionLocator(segmentLabels, segmentId, motionName);
    motionLocationInd = find(namedSegmentId(:, 1) <= segmentPassCount);
    motionLocationCount = motionLocations(motionLocationInd, :);
    segmentCount = length(motionLocationInd);
    
    segmentTime = zeros(1, segmentCount*2);
    segmentLabel = cell(1, segmentCount*2);
    
    for i = 1:length(motionLocationInd)
        segStart = segmentInd(motionLocationCount(i, 1), 1); % combine the "up" and "down" motion
        segEnd = segmentInd(motionLocationCount(i, end), 2);
%         time = (segStart:segEnd)'/frameRate;
        
        segmentTime(2*i - 1) = segStart/frameRate;
        segmentTime(2*i) = segEnd/frameRate;
        
        segmentLabel{2*i - 1} = motionName;
        segmentLabel{2*i} = motionName;
    end
end

function [motionLocations, segmentId, segmentName] = motionLocator(segmentLabels, segmentCount, desiredSegment, fullSegmentsFlag)
    % find all the occurances of the 'desiredSegment'
    motionLocations = [];
    segmentId = [];
    segmentCountExpended = []; % once the segment has been consumed, add it here
    segmentName = {};
    
    for i = 1:length(segmentLabels)
% % %         if strcmpi(segmentLabels{i}, desiredSegment)
% % % %             segmentInd = find(segmentCount == segmentCount(i)); % pull all entries that match that ID
% % % %             endLoc = find(segmentCount == segmentCount(i), 2, 'last'); % pull just the last 2
% % %             segmentInd = [i; i+1];
% % %             
% % %             if isempty(motionLocations)
% % %                 motionLocations = segmentInd';
% % %                 segmentId = segmentCount(i)*ones(size(segmentInd))';
% % %             else
% % % %                 if size(motionLocations, 2) ~= size(segmentInd', 2)
% % % %                     segmentInd = [segmentInd; 0];
% % % %                 end
% % %                 
% % % 
% % %                 motionLocations = [motionLocations; segmentInd'];
% % %                 segmentId = [segmentId; segmentCount(i)*ones(size(segmentInd))'];
% % %             end

        if strcmpi(segmentLabels{i}, desiredSegment) || ...
                (strcmpi('ALLMOTIONS', desiredSegment) && ...
                (fullSegmentsFlag && ~sum(segmentCountExpended == segmentCount(i)) || ~fullSegmentsFlag)) % matching by segment id
            currSegmentCount = segmentCount(i);
            
            % if it is on fullSegment mode, and the motion is one of the
            % variants, force the overall label to be one of the accepted
            % versions
            if fullSegmentsFlag
                currLabel = fullMotionLabel(segmentLabels{i});
            else
                currLabel = segmentLabels{i};
            end
            
            if fullSegmentsFlag
                segCountInd = find(segmentCount == currSegmentCount);
            else
                segCountInd = i;
            end
            
            segmentInd = [segCountInd(1); segCountInd(end)];
            segmentCountExpended = [segmentCountExpended, currSegmentCount];
            
            if isempty(motionLocations)
                % initialize the array with 
                motionLocations = segmentInd';
                segmentId = segmentCount(i);
                segmentName{1} = currLabel;
            else
                motionLocations = [motionLocations; segmentInd'];
                segmentId = [segmentId; segmentCount(i)];
                segmentName{end+1} = currLabel;
            end
        end
    end
    
    segmentName = segmentName';
end

function [segmentBreakdown, segmentSorted] = segmentAnalysis(segmentNames)
    segSorted = sort(segmentNames);
    segUnique = unique(segSorted, 'first');
    segCount = zeros(size(segUnique));
    
    for i = 1:length(segSorted)
        ind = find(strcmpi(segSorted{i}, segUnique));
        segCount(ind) = segCount(ind) + 1;
    end
    
    [sortedVal, sortMap] = sort(segCount, 1, 'descend');
    sortSegUnique = segUnique(sortMap);
    
    segmentBreakdown = cell(length(segUnique), 2);
    segmentSorted = cell(length(segUnique), 2);
    
    segmentBreakdown(:, 1) = segUnique;
    segmentSorted(:, 1) = sortSegUnique;
    
    for i = 1:length(segUnique)
        segmentBreakdown{i, 2} = segCount(i);
        segmentSorted{i, 2} = sortedVal(i);
    end
end

function label = fullMotionLabel(currLabel)
    switch currLabel
        case 'LKAR'
            label = 'LKE';
            
        case 'LPAR'
            label = 'LPE';
            
        case 'LPUE'
            label = 'LPE';
            
        case 'RKAR'
            label = 'RKE';
            
        case 'RPAR'
            label = 'RPE';
            
        otherwise
            label = currLabel;
    end
end