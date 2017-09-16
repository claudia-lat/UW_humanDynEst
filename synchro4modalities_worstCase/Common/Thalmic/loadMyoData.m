function [myoEMG, myoEMGTemp] = loadMyoData(targetPath)
    % load Myo EMG data from Myo MATLAB collection interface
    % data is returned in UTC 0, microseconds from 1970-1-1
    
    load(targetPath);
    clear targetPath % keep the workspace clear for the next step
    
    % rename the myo variable to something generic
    workspaceList = whos;
    myoEMGTemp = eval(workspaceList.name);
    
    startInd = 2; % remove some timesteps
    dayInMS = 24*60*60*1000; % mod out the date stamp
    
    % sort out the data. pull out the EMG data first
    entries = cell2mat(myoEMGTemp(:,1)) == 2; 
    emgTimeTemp = cell2mat(myoEMGTemp(entries, 2));
    emgTime = myoTimeToASL(emgTimeTemp);    
    emgData = cell2mat(myoEMGTemp(entries, 3));
    
    % need to clean the EMG data. ignoring repeated timestamps...
    [emgTimeClean, emgDataClean] = cleanRepeatedTimestamps(emgTime, emgData);
    myoEMG.emgTime = emgTimeClean(startInd:end, :); % shift time into seconds;
    myoEMG.emgData = emgDataClean(startInd:end, :);
    
    % now pull the IMU data
    entries = cell2mat(myoEMGTemp(:,1)) == 0; 
    imuTimeTemp = cell2mat(myoEMGTemp(entries, 2));
    imuTime = myoTimeToASL(imuTimeTemp);
    imuData = cell2mat(myoEMGTemp(entries, 3));  
    
    % just in case, clean the IMU data too
    [imuTimeClean, imuDataClean] = cleanRepeatedTimestamps(imuTime, imuData);
    myoEMG.imuTime = imuTimeClean(startInd:end, :); % shift time into seconds;
    myoEMG.imuData = imuDataClean(startInd:end, :);    
    
    myoEMG.emgTime =  myoEMG.emgTime / 1000;
    myoEMG.imuTime =  myoEMG.imuTime / 1000;
    
%     a = cell2mat(myoEMG(cell2mat(myoEMG(:,1)) == 2, 3));
%     plot(a)
end

function [newTimeOut, newDataOut] = cleanRepeatedTimestamps(time, data)
    cleanMode = 2;
    rescale = 1;
    
    if cleanMode == 1
        % return only the latest timestamp
        [newTimeOut,IA,IC] = unique(time, 'last');
        newDataOut = data(IA, :);
    elseif cleanMode == 2
        % interpolate the timestamp 
        newTime = time;
        newData = data;
        [IATime,IA,IC] = unique(time, 'last');
        for ind = 2:length(IA)
            prevIA = IA(ind-1);
            currIA = IA(ind);
            diffIA = currIA - prevIA;
            diffTime = IATime(ind) - IATime(ind-1);
            slope = diffTime/diffIA;
            newTimeArray = IATime(ind-1):slope:IATime(ind);
            newTime(prevIA:currIA) = newTimeArray;
        end
        
        newTimeOut = newTime(IA(1):end);
        newDataOut = newData(IA(1):end, :);
    end
    
    if rescale
        emgTimeS = newTimeOut/1000';
        emgDt = floor(1/mean(diff(emgTimeS)));
        
        % ensure uniqueness in x time array
        [x,IA,IC] = unique(emgTimeS);
        y = newDataOut(IA, :);
        
%         x = emgTimeS;
%         y = newDataOut;
        xx = (emgTimeS(2):1/emgDt:emgTimeS(end-1))';
        newDataOut = interp1(x, y, xx, 'linear');
        newTimeOut = xx*1000;
    end
end

function aslFormat = myoTimeToASL(myoFormat)
    % myo: UTC -5, microseconds from 1970-1-1
    % asl: UTC  0, milliseconds from 1970-1-1    
    
    unitScale = 10^-3;
    utcOffset = -5*(60*60) * 10^3;
    aslFormat = double(myoFormat)*unitScale + utcOffset;    
end