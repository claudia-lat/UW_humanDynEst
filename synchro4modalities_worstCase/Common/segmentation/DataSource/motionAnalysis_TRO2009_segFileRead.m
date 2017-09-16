function segmentData = motionAnalysis_TRO2009_segFileRead(fileToImport)
    % This function was designed to read a motionanalysis segment labelled data. It
    % was written specifically to read Dana's TRO2009 segmentation information
    
    delimiter = ',.'; % tab char
    
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
        
        segmentInfo(j, 1) = round(str2num(delim{1})/3);
        segmentInfo(j, 2) = round(str2num(delim{2})/3);
        segmentName{j, 1} = delim{3};
        segmentId(j, 1) = str2num(delim{4});
   
        tline = fgetl(fid);
    end
    
    segmentData.header = markername;
    segmentData.segmentId = segmentId;
    segmentData.segmentName = segmentName;
    segmentData.segmentTime = segmentInfo;
end