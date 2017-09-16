function segData = parseCSV_segment(filepath)
    % accepts the filepath and calls parseCSV, then perform some basic
    % post-processing for ease of use. this function scales the timestamps
    % to [seconds from 1970-01-01] 
    
    % load the data via parseCSV
    if ~exist(filepath, 'file')
        error('Segment file does not exist: %s', filepath);
    end
    
    segData = parseCSV(filepath);
    
        % check the time vector
    day2minMultiplier = 24*60*60;
%     assessTimeMS = datenum('1970-1-1') + ekfData.SystemMSTimeStamp(1)/(1000*day2minMultiplier);
    assessTimeS = datenum('1970-1-1') + segData.TimeStart(1)/(day2minMultiplier);

    if assessTimeS > now
        % if this statement is true, then it suggests that the timestamp is
        % in milliseconds and should be scaled down by 1000
         segData.timeStart =  segData.TimeStart/1000;
         segData.timeEnd =    segData.TimeEnd/1000;
    else
        segData.timeStart =  segData.TimeStart;
        segData.timeEnd =    segData.TimeEnd;
    end
    
    % removing TimeStart and TimeEnd for uniformity
    segData = rmfield(segData, {'TimeStart', 'TimeEnd'});
end