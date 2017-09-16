function cortexData = parseCSV_cortex(filepath, headerList)
    % accepts the filepath and calls parseCSV, then perform some basic
    % post-processing for ease of use. this function scales the timestamps
    % to [seconds from 1970-01-01] and groups the joint angles and other
    % appropriate data into one matrix
    
    % list of header entries that we are expecting
%     headerList = {'R_Shoulder_x', 'R_Shoulder_y', 'R_Shoulder_z', ...
%         'L_Shoulder_x', 'L_Shoulder_y', 'L_Shoulder_z', ...
%         'R_ASIS_x', 'R_ASIS_y', 'R_ASIS_z', ...
%         'L_ASIS_x', 'L_ASIS_y', 'L_ASIS_z', ...
%         'R_Knee_Medial_x', 'R_Knee_Medial_y', 'R_Knee_Medial_z', ...
%         'R_Knee_Lateral_x', 'R_Knee_Lateral_y', 'R_Knee_Lateral_z', ...
%         'R_Ankle_Medial_x', 'R_Ankle_Medial_y', 'R_Ankle_Medial_z', ...
%         'R_Ankle_Lateral_x', 'R_Ankle_Lateral_y', 'R_Ankle_Lateral_z', ...
%         'R_Toe_x', 'R_Toe_y', 'R_Toe_z', ...
%         'R_Heel_x', 'R_Heel_y', 'R_Heel_z', ...
%         'Hip_Shimmer_x', 'Hip_Shimmer_y', 'Hip_Shimmer_z', ...
%         'Knee_Shimmer_x', 'Knee_Shimmer_y', 'Knee_Shimmer_z', ...
%         'Ankle_Shimmer_x', 'Ankle_Shimmer_y', 'Ankle_Shimmer_z'};
    
    % needs this headerlist in order to determine which marker set we are
    % looking for, and parse them properly, since there are some
    % inconsistencies between each set
    if ~exist('headerList', 'var')
        % healthy1 list
        headerList = {'R_Shoulder', 'L_Shoulder', ...
            'R_ASIS', 'L_ASIS', ...
            'R_Knee_Medial', 'R_Knee_Lateral', 'R_Ankle_Medial', 'R_Ankle_Lateral', ...
            'R_Toe', 'R_Heel', ...
            'Hip_Shimmer', 'Knee_Shimmer', 'Ankle_Shimmer'};
        combineArrayList = {'R_Knee_Medial', 'R_Knee_Lateral', 'R_Ankle_Medial', 'R_Ankle_Lateral'};
        
        % healthy2 list
%         headerList = {'R_Shoulder', 'L_Shoulder', ...
%             'R_ASIS', 'L_ASIS', ...
%             'R_Knee_Lat', 'R_Knee_Med', 'R_Ankle_Lat', 'R_Ankle_Med', ...
%             'R_Toe', 'R_Heel', ...
%             'S_Ankle', 'S_Knee', 'S_Waist'};
%         combineArrayList = {'R_Knee_Lat', 'R_Knee_Med', 'R_Ankle_Lat', 'R_Ankle_Med'};
    end

    offTrackVal = 9999999; % if a marker disappears, it is replaced by this val
    
    % load the data via parseCSV
    cortexDataTemp = parseCSV(filepath);
    
    if isempty(cortexDataTemp)
        % wasn't able to load the file. return a blank
        cortexData = [];
        return
    end
    
    cortexData.Frame = cortexDataTemp.Frame;
    
    % check the time vector
    day2minMultiplier = 24*60*60;
%     assessTimeMS = datenum('1970-1-1') + ekfData.SystemMSTimeStamp(1)/(1000*day2minMultiplier);
    cortexData.SystemMSTimeStamp = cortexDataTemp.SystemMSTimeStamp;
    assessTimeS = datenum('1970-1-1') + cortexData.SystemMSTimeStamp(1)/(day2minMultiplier);
    
    % check for end-of-day wraparound. ie the clock went from 11.59.59 -> 00.00.00
    diffMS = diff(cortexData.SystemMSTimeStamp);
    [minVal, minInd] = min(diffMS);
    
    if assessTimeS > now
        % if this statement is true, then it suggests that the timestamp is
        % in milliseconds and should be scaled down by 1000
        if minVal < 0 % negative diff...
            cortexData.SystemMSTimeStamp(minInd+1:end) = ...
                cortexData.SystemMSTimeStamp(minInd+1:end) + 24*60*60*1000;
        end
        
        cortexData.SystemSTimeStamp = cortexData.SystemMSTimeStamp/1000;
    else
        if minVal < 0 % negative diff...
            cortexData.SystemMSTimeStamp(minInd+1:end) = ...
                cortexData.SystemMSTimeStamp(minInd+1:end) + 24*60*60;
        end
        
        cortexData.SystemSTimeStamp = cortexData.SystemMSTimeStamp;
    end
    
    % look for marker skip and interpolate to fill in
    fieldNames = fieldnames(cortexDataTemp);
    lengthData = size(cortexData.SystemSTimeStamp, 1);
    
    % uniform the header information
    prefixString = ''; % pull out any information that prefixes the headers
%     for i = 1:length(fieldNames)
%         [matchstart,matchend,tokenindices,matchstring,tokenstring,tokenname,splitstring] ...
%             = regexp(fieldNames{i}, headerList{1});
%         
%         if ~isempty(matchstart)
%             prefixString = splitstring{1};
%             break
%         end
%     end
    
    for i = 1:length(headerList)
        prefixString = ''; 
        headerString = '';
        
        for j = 1:length(fieldNames)
            [matchstart,matchend,tokenindices,matchstring,tokenstring,tokenname,splitstring] ...
                = regexp(fieldNames{j}, headerList{i}, 'ignorecase');
            
            if ~isempty(matchstart)
                prefixString = splitstring{1};
                headerString = matchstring{1};
                break
            end
        end
        
        if length(headerString) > 0
            eval(['cortexData.' headerList{i} '_x = cortexDataTemp.' prefixString '' headerString '_x;']);
            eval(['cortexData.' headerList{i} '_y = cortexDataTemp.' prefixString '' headerString '_y;']);
            eval(['cortexData.' headerList{i} '_z = cortexDataTemp.' prefixString '' headerString '_z;']);
        end
    end
    
    fieldNames = fieldnames(cortexData);
    maxStartIndError = 1; % track the points where the markers disappear, to note where to crop
    minEndIndError = lengthData; % remove the first and last points anyway
    markersToCheck = 'R_ASIS|Knee|Ankle';
    for i = 4:length(fieldNames) % looking at each dof independently
        % however, we only want to match certain motions
        [matchstart,matchend,tokenindices,matchstring,tokenstring,tokenname,splitstring] ...
            = regexp(fieldNames{i}, markersToCheck);
        
        if isempty(matchstart)
           continue % skip the ones that doesn't match our list of the things we want to check for
        end
        
%         eval(['sensorDataInsp = cortexData.' fieldNames{i} ';']);
        sensorDataInsp = cortexData.(fieldNames{i});
        [clusterArray, startIndError, endIndError] = interpolateCluster(sensorDataInsp, offTrackVal);
        
        for j = 1:size(clusterArray, 1)
            startInd = clusterArray(j, 1) - 1;
            endInd = clusterArray(j, 2) + 1;
            timeFullSeg = cortexData.SystemSTimeStamp(startInd:endInd); % full time array wanted
            timeSeg = cortexData.SystemSTimeStamp([startInd endInd]); % two time points that correspond to edge points
            dataSeg = sensorDataInsp([startInd endInd]); % corresponding data points
            
            % account for cases where there are only 2 points, since
            % splining doesn't seem to work well with them
            if length(timeSeg) == 2 && length(timeFullSeg) == 3
%                 dataSplined = [dataSeg(1) mean(dataSeg) dataSeg(2)];
                dataSplined = interp1(timeSeg, dataSeg, timeFullSeg, 'linear');
            else
                dataSplined = spline(timeSeg, dataSeg, timeFullSeg);
            end
            
            cortexData.(fieldNames{i})(startInd:endInd) = dataSplined;
%             eval(['cortexData.' fieldNames{i} '(startInd:endInd) = dataSplined;']);
        end
        
        if maxStartIndError < startIndError
            maxStartIndError = startIndError;
        end
        
        if minEndIndError > endIndError && endIndError > 0
            minEndIndError = endIndError - 1;
        end
    end
    
    % commit the crop to remove edge data that does not have proper marker 
    % data, using maxStartIndError and minEndIndError, then  consolidate 
    % the cortex data    
    cortexData.Frame = cortexData.Frame(maxStartIndError:minEndIndError);
    cortexData.SystemMSTimeStamp = cortexData.SystemMSTimeStamp(maxStartIndError:minEndIndError);
    cortexData.SystemSTimeStamp = cortexData.SystemSTimeStamp(maxStartIndError:minEndIndError);
    for i = 1:length(headerList)
        eval(['cortexData.' headerList{i} '_x = cortexData.' headerList{i} '_x(maxStartIndError:minEndIndError);']);
        eval(['cortexData.' headerList{i} '_y = cortexData.' headerList{i} '_y(maxStartIndError:minEndIndError);']);
        eval(['cortexData.' headerList{i} '_z = cortexData.' headerList{i} '_z(maxStartIndError:minEndIndError);']);
        
        eval(['cortexData.' headerList{i} '   = ' ...
            '[cortexData.' headerList{i} '_x ' ...
            'cortexData.' headerList{i} '_y ' ...
            'cortexData.' headerList{i} '_z];']);
    end
    
    % combine the medial and lateral joints
    lengthData = size(cortexData.SystemSTimeStamp, 1);
    cortexData.R_Knee = mean(reshape([cortexData.(combineArrayList{1}) cortexData.(combineArrayList{2})], lengthData, 3, 2), 3);
    cortexData.R_Ankle = mean(reshape([cortexData.(combineArrayList{3}) cortexData.(combineArrayList{4})], lengthData, 3, 2), 3);
end

function [clusterArray, startIndError, endIndError] = interpolateCluster(sensorDataCol, offTrackVal)
    % find the number of "time clusters" where the markers become
    % untrackable, and note their starting and ending points. These points
    % will get interpolated
    
    % clusterArray[1] = start
    % clusterArray[2] = end
    
    clusterInd = 0;
    clusterArray = [];
    
    offTrackArray = find(sensorDataCol == offTrackVal);
    for i = 1:length(offTrackArray)
        if isempty(clusterArray)
            % first entry
            clusterInd = clusterInd + 1;
            
            clusterArray(clusterInd, 1) = offTrackArray(i); 
            clusterArray(clusterInd, 2) = offTrackArray(i);             
        else
            if offTrackArray(i) == clusterArray(clusterInd, 2) + 1
                % if next value is incriment from previous
                clusterArray(clusterInd, 2) = offTrackArray(i);
            else
                % new column
                clusterInd = clusterInd + 1;
                
                clusterArray(clusterInd, 1) = offTrackArray(i);
                clusterArray(clusterInd, 2) = offTrackArray(i);
            end
        end
    end
    
    % the following sets of data should be removed by cropping anyway, but
    % we won't process it at this stage

    % if the last cluster goes all the way to the end, drop that cluster,
    % since it's likely caused by actor going off the capture area, and
    % cannot be interpolated properly anyway
    if ~isempty(clusterArray) && clusterArray(clusterInd, 2) == length(sensorDataCol)
        endIndError = clusterArray(end, 1);
        clusterInd = clusterInd - 1;
        clusterArray = clusterArray(1:clusterInd, 1:2);
    else
        endIndError = 0;
    end
    
    % also, if the first cluster is at the beginning, then we can't do
    % anything about that either, so we'll have to drop that
    if ~isempty(clusterArray) && clusterArray(1, 1) == 1
        startIndError = clusterArray(1, 2);
        clusterArray = clusterArray(2:clusterInd, 1:2);
    else
        startIndError = 0;
    end  
end