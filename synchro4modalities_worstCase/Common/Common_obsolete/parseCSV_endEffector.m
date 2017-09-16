function ekfData = parseCSV_endEffector(filepath)
    % accepts the filepath and calls parseCSV, then perform some basic
    % post-processing for ease of use. this function scales the timestamps
    % to [seconds from 1970-01-01] and groups the endeffectors and other
    % appropriate data into one matrix, for Q, dQ and ddQ
    
    % load the data via parseCSV
    ekfData = parseCSV(filepath);
    
    % check the time vector
    day2minMultiplier = 24*60*60;
%     assessTimeMS = datenum('1970-1-1') + ekfData.SystemMSTimeStamp(1)/(1000*day2minMultiplier);
    assessTimeS = datenum('1970-1-1') + ekfData.SystemMSTimeStamp(1)/(day2minMultiplier);

    if assessTimeS > now
        % if this statement is true, then it suggests that the timestamp is
        % in milliseconds and should be scaled down by 1000
        ekfData.SystemSTimeStamp = ekfData.SystemMSTimeStamp/1000;
    else
        ekfData.SystemSTimeStamp = ekfData.SystemMSTimeStamp;
    end

    ekfData.EF1 = [ekfData.EF1x ekfData.EF1y ekfData.EF1z];
    ekfData.EF2 = [ekfData.EF2x ekfData.EF2y ekfData.EF2z];
end