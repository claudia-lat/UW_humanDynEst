function writeCSV_segment(targetFile, segmentInfo)
    % make data file for segmentation
    % This function expects the targetFile, and 'segmentInfo', which is a
    % struct that has 4 fields, each holding an array: 
    %   SegmentCount - An indices for the segment: ie [1 2 3 4 5]
    %   Use - 0 for 'don't use this segment', 1 for 'use this segment'
    %   TimeStart - the start of a segment
    %   TimeEnd - the end of a segment
    % Time values are expected to be in [ms], elapsed from 1970-1-1

    % [legacy support]
    if isfield(segmentInfo, 't')
        if iscell(segmentInfo.t)
            % the old 'manual_segment'
            segmentInfo.SegmentCount = 1:length(segmentInfo.t);
            segmentInfo.Use = segmentInfo.use;
            
            timeStart = zeros(size(segmentInfo.SegmentCount));
            timeEnd = zeros(size(segmentInfo.SegmentEnd));
            
            for i = 1:length(segmentInfo.t)
                timeStart(i) = segmentInfo.t{i}(1);
                timeEnd(i) = segmentInfo.t{i}(2);
            end
            
            segmentInfo.TimeStart = timeStart;
            segmentInfo.TimeEnd = timeEnd;
        else
            % the old 'crop'            
            segmentInfo.SegmentCount = 1;
            segmentInfo.Use = 1;
            
            segmentInfo.TimeStart = segmentInfo.t(1);
            segmentInfo.TimeEnd = segmentInfo.t(2);
        end
        
        fields = {'t','use'};
        segmentInfo = rmfield(segmentInfo,fields);
        
    elseif isfield(segmentInfo, 'segmentTime')
        segmentInfo.SegmentCount = (1:length(segmentInfo.segmentId))';
        segmentInfo.Use = ones(size(segmentInfo.SegmentCount));
        segmentInfo.TimeStart = segmentInfo.segmentTime(1, :)';
        segmentInfo.TimeEnd = segmentInfo.segmentTime(2, :)';
        
        fields = {'segmentId','segmentTime', 'segmentMinLL', 'loglikMtx', 'segmentCounter'};
        segmentInfo = rmfield(segmentInfo,fields);
    end
    
    % the 'prefered' way
    writeCSV(targetFile, segmentInfo);

%     % old way
%     [fId, msg] = fopen(targetFile, 'w');
%     fprintf(fId, 'SegmentCount,Use,TimeStart,TimeEnd');
%     fprintf(fId, '\r\n');
%     
%     for i = 1:length(segmentInfo.SegmentCount)
%         fprintf(fId, '%u,%u,%5.5f,%5.5f', ...
%             segmentInfo.SegmentCount(i), segmentInfo.Use(i), segmentInfo.TimeStart(i), segmentInfo.TimeEnd(i));
%         
%         fprintf(fId, '\r\n');
%     end
%     
%     fclose(fId);
end