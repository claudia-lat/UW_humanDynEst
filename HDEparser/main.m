
clc;
close all;
clear;


%% Extracting data

% ----Human forces
filename_dumpForces = 'humanForces/data.log';
forces = parseHumanForces(filename_dumpForces, 2); 
% since this dataset consider only the 2 forces exchanged with the
% forceplates.

% ----Human state
filename_dumpState = 'humanState/data.log';
state = parseHumanState(filename_dumpState);

% ----Dynamic estimation (vector d)
filename_dumpDynEst = 'humanDynEstimation/data.log';
d = parseHumanDynEstimation(filename_dumpDynEst);

%% Downsampling

% 1. Compute the time sampling from aquired data
forces_diff = zeros(1, length(forces.time)-1 );
for i = 1: length(forces.time)-1
    forces_diff(i) = forces.time(:,i+1) - forces.time(:,i);  
end
mean_forces_time = mean(forces_diff);

state_diff = zeros(1, length(state.time)-1 );
for i = 1: length(state.time)-1
    state_diff(i) = state.time(:,i+1) - state.time(:,i);  
end
mean_state_time = mean(state_diff);

d_diff = zeros(1, length(d.time)-1 );
for i = 1: length(d.time)-1
    d_diff(i) = d.time(:,i+1) - d.time(:,i);  
end
mean_d_time = mean(d_diff);

% 2. Check the bigger time sampling
if (mean_forces_time >= mean_state_time) && (mean_forces_time >= mean_d_time)
    timeForSampling = mean_forces_time;
    sampling_master_time = forces.time;
    sampling_master = 'forces';
end

if (mean_state_time >= mean_forces_time) && (mean_state_time >= mean_d_time)
    timeForSampling = mean_state_time;
    sampling_master_time = state.time;
    sampling_master = 'state';
end

if (mean_d_time >= mean_forces_time) && (mean_d_time >= mean_state_time)
    timeForSampling = mean_d_time;
    sampling_master_time = d.time;
    sampling_master = 'd';
end

fprintf('------------------------------------------------------------\n')
fprintf('The sampling time is %d sec related to <%s> \n',timeForSampling, sampling_master);
fprintf('------------------------------------------------------------\n')


% 3. Downsampling of the data
interpData = struct;

% ----- Forces
for j = 1: size(forces.forces.RightFoot.value,1)
    interpData.forces.RightFoot.value(j,:) = interp1(forces.time, forces.forces.RightFoot.value(j,:), sampling_master_time);
    interpData.forces.LeftFoot.value(j,:)  = interp1(forces.time, forces.forces.LeftFoot.value(j,:), sampling_master_time);
end
    
% ----- State
for j = 1: size(state.qj,1)
    interpData.state.qj(j,:) = interp1(state.time, state.qj(j,:), sampling_master_time);
    interpData.state.dqj(j,:) = interp1(state.time, state.qj(j,:), sampling_master_time);
end
for j = 1: size(state.basePose,1)
    interpData.state.basePose(j,:) = interp1(state.time, state.basePose(j,:), sampling_master_time);
    interpData.state.baseVelocity(j,:) = interp1(state.time, state.baseVelocity(j,:), sampling_master_time);
end
    
% ----- Vector d
interpData.d.links = d.links;

for link = fieldnames(interpData.d.links)
    for indexField = 1 : size(state.qj,1)
        sublink = fieldnames(interpData.d.links.(link{indexField}));   
        for ind = 1 : length(sublink)
            interpData.d.links.(link{indexField}).(sublink{ind}) = zeros(6, length(sampling_master_time));
            for ind2 = 1 : size(d.links.Head.acceleration,1)
                 interpData.d.links.(link{indexField}).(sublink{ind})(ind2,:) = interp1(d.time,...
                                                                                d.links.(link{indexField}).(sublink{ind})(ind2,:),...
                                                                                sampling_master_time);
            end
        end     
    end
end

interpData.d.joints = d.joints;

for joint = fieldnames(interpData.d.joints)
    for indexField = 1 : size(state.qj,1)
        subjoint = fieldnames(interpData.d.joints.(joint{indexField}));   
        for ind = 1 : length(subjoint)
            
            if ind == 1 % only the first element of the subjoint has got 6 values
                interpData.d.joints.(joint{indexField}).(subjoint{ind}) = zeros(6, length(sampling_master_time)); 
                for ind2 = 1 : size(d.joints.jC1Head_rotx.transmittedWrench,1)
                     interpData.d.joints.(joint{indexField}).(subjoint{ind})(ind2,:) = interp1(d.time,...
                                                                    d.joints.(joint{indexField}).(subjoint{ind})(ind2,:),...
                                                                    sampling_master_time);
                end
            else 
                interpData.d.joints.(joint{indexField}).(subjoint{ind}) = zeros(1, length(sampling_master_time)); 
                interpData.d.joints.(joint{indexField}).(subjoint{ind}) = interp1(d.time,...
                                                                                d.joints.(joint{indexField}).(subjoint{ind}),...
                                                                                sampling_master_time);
            end
        end     
    end
end


% for plotting data
plotData;
