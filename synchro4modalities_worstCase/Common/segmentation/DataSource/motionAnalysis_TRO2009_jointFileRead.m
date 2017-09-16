function jointData = motionAnalysis_TRO2009_jointFileRead(fileToImport)
    % This function was designed to read a motionanalysis joint data. It
    % was written specifically to read Dana's TRO2009 joint information
    
    delimiter = '\t'; % tab char
    
    % opening file
    fid = fopen(fileToImport,'r');
    
    % header data
    tline = fgetl(fid);
    temp = textscan(tline, '%s', 'delimiter', delimiter);
    delim = temp{1};
      
    j = 0;
    for i = 1:length(delim)
        if ~isempty(delim{i})
            j = j + 1;
            markername{j} = delim{i};
%             marker{j} = zeros(numFrame, 3);
        end
    end
    
    j = 0;
    tline = fgetl(fid);
    
    while ischar(tline)
        temp = textscan(tline, '%s', 'delimiter', delimiter);
        delim = temp{1};
        j = j + 1;

        for i = 1:length(delim)
            jointdata(j, i) = str2num(delim{i});
        end
        
        tline = fgetl(fid);
    end
    
    jointData.marker = markername;
    jointData.joint = jointdata;
end