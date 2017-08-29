function [ parsed_dynEst] = parseHumanDynEstimation( filename_dumpDynEst )
%PARSEHUMANDYNESTIMATION parses forces coming from a YARP file of HDE repo
% (https://github.com/robotology/human-dynamics-estimation) into a Matlab 
% struct.  Taylored for a model with 66 DoF
%
% Input: 
% - filename_dumpDynEst: name of the file.log         
% Output:
% - parsed_dynEst: parsed human dynamics estimation vector in a Matlab 
%                  struct
%
%
% The parser is built on the following thrift:
%
% struct LinkDynamicsEstimation {
% 
%     1: string linkName;
%     // link spatial accelerations (vector 6D)
%     2: Vector spatialAcceleration;
% 
%     // net spatial wrench on body (vector 6D)
%     3: Vector netWrench;
% 
%     // external wrench acting on body (vector 6D)
%     4: Vector externalWrench;
% 
% }
% 
% struct JointDynamicsEstimation {
% 
%     1: string jointName;
%     // spatial wrench transmitted to body from his father (vector 6D)
%     2: Vector transmittedWrench;
% 
%     // joint torque
%     3: Vector torque;
% 
%     // joint acceleration
%     4: Vector acceleration;
% 
% }
% 
% struct HumanDynamics {
%     1: list<LinkDynamicsEstimation> linkVariables;
%     2: list<JointDynamicsEstimation> jointVariables;
% }
%

fileID = fopen(filename_dumpDynEst);

numberOfLinks = 66;
numberOfJoints = 66;

formatSpec = '%d %f';

formatSpec = [formatSpec, ''];
for i = 1 : numberOfLinks
    formatSpec = [formatSpec, '%q '];
    for j = 1 : 3
        formatSpec = [formatSpec, ''];
        for k = 1 : 6
            formatSpec = [formatSpec, '%f '];
        end
        formatSpec = [formatSpec, ''];
    end
    formatSpec = [formatSpec, ''];
end

formatSpec = [formatSpec, ''];

formatSpec = [formatSpec, ''];

for i = 1 : numberOfJoints
    formatSpec = [formatSpec, '%q '];
    formatSpec = [formatSpec, ''];
    for k = 1 : 6
        formatSpec = [formatSpec, '%f '];
    end
    formatSpec = [formatSpec, ''];
       
    for j = 1 : 2
        formatSpec = [formatSpec, ''];
        for k = 1 : 1
            formatSpec = [formatSpec, '%f '];
        end
        formatSpec = [formatSpec, ''];
    end
    formatSpec = [formatSpec, ''];
end

formatSpec = [formatSpec, ''];

C = textscan(fileID, formatSpec, ...
    'MultipleDelimsAsOne', 1, 'Delimiter', {'(',')','\b'});
fclose(fileID);

%now we should "map" C to a proper structure
numOfSamples = length(C{1});
parsed_dynEst.time = C{2}';
% normalize time to zero
parsed_dynEst.time = parsed_dynEst.time - repmat(parsed_dynEst.time(1), size(parsed_dynEst.time));

for i = 1 : numberOfLinks
    startingLinkIndex = 2 + ((i -1) * 19 + 1);
    
    linkName = strtrim(C{1, startingLinkIndex}{1});
    linkData.acceleration = zeros(6, numOfSamples);
    for col = 1 : size(linkData.acceleration, 1)
        linkData.acceleration(col, :) = C{:, startingLinkIndex + col}';
    end
    linkData.netForces = zeros(6, numOfSamples);
    for col = 1 : size(linkData.netForces, 1)
        linkData.netForces(col, :) = C{:, startingLinkIndex + 6 + col}';
    end
    linkData.extForces = zeros(6, numOfSamples);
    for col = 1 : size(linkData.extForces, 1)
        linkData.extForces(col, :) = C{:, startingLinkIndex + 12 + col}';
    end
    parsed_dynEst.links.(linkName) = linkData;  
end

for i = 1 : numberOfJoints
    startingLinkIndex = 2 + numberOfLinks * 19 + ((i -1) * 9 + 1);
    
    jointName = strtrim(C{1, startingLinkIndex}{1});
    jointData.transmittedWrench = zeros(6, numOfSamples);
    for col = 1 : size(jointData.transmittedWrench, 1)
        jointData.transmittedWrench(col, :) = C{:, startingLinkIndex + col}';
    end
    jointData.jointTorque = zeros(1, numOfSamples);
    for col = 1 : size(jointData.jointTorque, 1)
        jointData.jointTorque(col, :) = C{:, startingLinkIndex + size(jointData.transmittedWrench, 1) + col}';
    end
    jointData.jointAcc = zeros(1, numOfSamples);
    for col = 1 : size(jointData.jointAcc, 1)
        jointData.jointAcc(col, :) = C{:, startingLinkIndex + size(jointData.transmittedWrench, 1) + size(jointData.jointAcc, 1) + col}';
    end
    parsed_dynEst.joints.(jointName) = jointData;
    
end
end
