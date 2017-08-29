function [ parsed_forces] = parseHumanForces( filename_dumpForces, numberOfForces )
%PARSEHUMANFORCES parses forces coming from a YARP file of HDE repo
% (https://github.com/robotology/human-dynamics-estimation) into a Matlab 
% struct.
%
% Input: 
% - filename_dumpForces: name of the file.log
% - numberOfForces: number of forces involved in the analysis. For example,
%                   it is 2 if there are only 2 forceplates, it is 4 if 
%                   there are a combination of 2 forceplates and 2 robot
%                   contacts.             
% Output:
% - parsed_forces: parsed human forces in a Matlab struct.
%
%
% The parser is built on the following thrift:
%
% struct Force6D {
%     /**
%      * link in which the 6D Force is applied
%      */
%     1: string appliedLink;
%     
%     /**
%      * frame on which the 6D force is expressed
%      */
%     2: string expressedFrame;
%     
%     3: double fx;
%     4: double fy;
%     5: double fz;
% 
%     6: double ux;
%     7: double uy;
%     8: double uz;
% 
% }
% 
% struct HumanForces {
%     1 : list<Force6D> forces;
% }
%

fileID = fopen(filename_dumpForces);


formatSpec = '%d %f ';

formatSpec = [formatSpec, ''];

for i = 1 : numberOfForces
    formatSpec = [formatSpec, '%q %q '];
    for k = 1 : 6
        formatSpec = [formatSpec, '%f '];
    end
    formatSpec = [formatSpec, ''];
    
end
formatSpec = [formatSpec, ''];

C = textscan(fileID, formatSpec, ...
    'MultipleDelimsAsOne', 1, 'Delimiter', {'(',')', ' ', '\b'});
fclose(fileID);

%now we should "map" C to a proper structure
numOfSamples = length(C{1});
parsed_forces.time = C{2}';
% normalize time to zero
parsed_forces.time = parsed_forces.time - repmat(parsed_forces.time(1), size(parsed_forces.time));

for i = 1 : numberOfForces
    startingLinkIndex = 2 + ((i -1) * (6 + 2) + 1);
    
    linkName = strtrim(C{1, startingLinkIndex}{1});
    linkData.frameName = strtrim(C{1, startingLinkIndex + 1}{1});
    linkData.value = zeros(6, numOfSamples);
    
    for col = 1 : size(linkData.value, 1)
        linkData.value(col, :) = C{:, startingLinkIndex + 1 + col}';
    end
    
    parsed_forces.forces.(linkName) = linkData;  
end
end
