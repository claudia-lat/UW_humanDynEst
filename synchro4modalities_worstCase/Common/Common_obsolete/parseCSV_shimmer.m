function shimmerData = parseCSV_shimmer(filepath)
    % accepts the filepath and calls parseCSV, then perform some basic
    % post-processing for ease of use. this function scales the timestamps
    % to [seconds from 1970-01-01] and groups the endeffectors and other
    % appropriate data into one matrix, for Q, dQ and ddQ
    
    % load the data via parseCSV
    shimmerData = parseCSV(filepath);
    
    % check the time vector
    day2minMultiplier = 24*60*60;
%     assessTimeMS = datenum('1970-1-1') + ekfData.SystemMSTimeStamp(1)/(1000*day2minMultiplier);
    assessTimeS = datenum('1970-1-1') + shimmerData.SystemMsTimeStampCalibrated(1)/(day2minMultiplier);

    if assessTimeS > now
        % if this statement is true, then it suggests that the timestamp is
        % in milliseconds and should be scaled down by 1000
        shimmerData.SystemSTimeStamp = shimmerData.SystemMsTimeStampCalibrated/1000;
    else
        shimmerData.SystemSTimeStamp = shimmerData.SystemMsTimeStampCalibrated;
    end

    shimmerData.AccelerometerCalibrated = [shimmerData.AccelerometerXCalibrated shimmerData.AccelerometerYCalibrated shimmerData.AccelerometerZCalibrated];
    shimmerData.GyroscopeCalibrated = [shimmerData.GyroscopeXCalibrated shimmerData.GyroscopeYCalibrated shimmerData.GyroscopeZCalibrated];
end