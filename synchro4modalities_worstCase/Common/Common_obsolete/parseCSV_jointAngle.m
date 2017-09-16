function ekfData = parseCSV_jointAngle(filepath)
    % accepts the filepath and calls parseCSV, then perform some basic
    % post-processing for ease of use. this function scales the timestamps
    % to [seconds from 1970-01-01] and groups the joint angles and other
    % appropriate data into one matrix, for Q, dQ and ddQ
    
    % load the data via parseCSV
    if ~exist(filepath, 'file')
        error('Joint angle file does not exist: %s', filepath);
    end
    
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
    
    % now consolidate the joint angles    
    if isfield(ekfData, 'QD1')
        % switch it over to the other type ('dQ' vs 'QD')
        ekfData.dQ1 = ekfData.QD1;
        ekfData.dQ2 = ekfData.QD2;
        ekfData.dQ3 = ekfData.QD3;
        ekfData.dQ4 = ekfData.QD4;
        ekfData.dQ5 = ekfData.QD5;
        
        ekfData.ddQ1 = ekfData.QDD1;
        ekfData.ddQ2 = ekfData.QDD2;
        ekfData.ddQ3 = ekfData.QDD3;
        ekfData.ddQ4 = ekfData.QDD4;
        ekfData.ddQ5 = ekfData.QDD5;
        
        fields = {'QD1','QD2','QD3','QD4','QD5','QDD1','QDD2','QDD3','QDD4','QDD5'};
        ekfData = rmfield(ekfData,fields);
    elseif isfield(ekfData, 'S1')
        % shift from 'S1' to 'Q1'
%         ekfData.Q1 = ekfData.S1;
%         ekfData.Q2 = ekfData.S2;
%         ekfData.Q3 = ekfData.S3;
%         ekfData.Q4 = ekfData.S4;
%         ekfData.Q5 = ekfData.S5;
%         
%         ekfData.dQ1 = ekfData.S6;
%         ekfData.dQ2 = ekfData.S7;
%         ekfData.dQ3 = ekfData.S8;
%         ekfData.dQ4 = ekfData.S9;
%         ekfData.dQ5 = ekfData.S10;
%         
%         ekfData.ddQ1 = ekfData.S11;
%         ekfData.ddQ2 = ekfData.S12;
%         ekfData.ddQ3 = ekfData.S13;
%         ekfData.ddQ4 = ekfData.S14;
%         ekfData.ddQ5 = ekfData.S15;
%         
%         fields = {'S1','S2','S3','S4','S5','S6','S7','S8','S9','S10','S11','S12','S13','S14','S15'};

        ekfData.Q1 = ekfData.S1;
        ekfData.Q2 = ekfData.S2;
        ekfData.Q3 = ekfData.S3;
        ekfData.Q4 = ekfData.S4;
        ekfData.Q5 = ekfData.S5;
        ekfData.Q6 = ekfData.S6;
        ekfData.Q7 = ekfData.S7;
        
        ekfData.dQ1 = ekfData.S8;
        ekfData.dQ2 = ekfData.S9;
        ekfData.dQ3 = ekfData.S10;
        ekfData.dQ4 = ekfData.S11;
        ekfData.dQ5 = ekfData.S12;
        ekfData.dQ6 = ekfData.S13;
        ekfData.dQ7 = ekfData.S14;
        
        ekfData.ddQ1 = ekfData.S15;
        ekfData.ddQ2 = ekfData.S16;
        ekfData.ddQ3 = ekfData.S17;
        ekfData.ddQ4 = ekfData.S18;
        ekfData.ddQ5 = ekfData.S19;
        ekfData.ddQ6 = ekfData.S20;
        ekfData.ddQ7 = ekfData.S21;
        
        fields = {'S1','S2','S3','S4','S5','S6','S7','S8','S9','S10','S11','S12','S13','S14','S15','S16','S17','S18','S19','S20','S21'};

        ekfData = rmfield(ekfData,fields);
    end
    
    ekfData.Q = [ekfData.Q1 ekfData.Q2 ekfData.Q3 ekfData.Q4 ekfData.Q5 ekfData.Q6 ekfData.Q7];
    ekfData.dQ = [ekfData.dQ1 ekfData.dQ2 ekfData.dQ3 ekfData.dQ4 ekfData.dQ5 ekfData.dQ6 ekfData.dQ7];
    ekfData.ddQ = [ekfData.ddQ1 ekfData.ddQ2 ekfData.ddQ3 ekfData.ddQ4 ekfData.ddQ5 ekfData.ddQ6 ekfData.ddQ7];
end