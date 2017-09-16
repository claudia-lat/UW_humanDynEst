classdef exerciseDataHandle_generalized < matlab.mixin.Copyable
% exerciseDataHandle aggregiates all the data for a given exercise 
% occurance, and provide file I/O, as well as plotting functions. this
% class functions as a container for the other datasets, and should be
% accessed for all data loading and management
%
% This class can be used as part of a sessionDataHandle, or as an array of
% exerciseDataHandles

properties
    % file I/O
    dirPathExercise = ''; % the path to the base data
    datasetName = ''; % the project that this data is associated with
    
    %Pointer to the PATIENT object
    patient_hndl = 0;
    
    % demographic information
    subjectNumber = 0; % subject number
    sessionNumber = 0; % session
    exerciseName = ''; % the name of the folder
    
    % exercise info
    exerciseType = ''; % the type of exercise
    exerciseNameLong = '';
    kinematicDirection = ''; % the child data is parsed as a string, so this converts it back to an array
    initPosture = '';
    description = '';
    
    % identifier strings
    subjSessExer = '';
    
    % data files to load
    filepathDataMocap = [];
    filepathDataImu = [];
    filepathDataEkf = [];
    filepathDataSegManual = [];
    filepathDataSegGuidance = [];
    filepathDataSegCrop = [];
    filepathDataSegAlg = [];
    filepathDataTorque = [];
    filepathDataGRF = [];
    
    % available data
    dataMocap = [];
    dataImu = [];
    dataEkf = [];
    dataSegCrop = [];
    dataSegManual = [];
    dataSegGuidance = [];
    dataSegAlg = [];
    dataForces = [];
    
    jpToExtract;
    qToExtract;
    
    
    % legacy fields
    subjectName = [];
    session = [];
end % properties

methods
    function obj = exerciseDataHandle_generalized(varargin)
        constHeader = '.header';
        constData = '.data';

        if isstruct(varargin{1})
            % if it is a struct, there are existing data we can load into
            % this class. 
            specStruct = varargin{1};
            obj.dirPathExercise = specStruct.filePath;
            
            if isfield(specStruct, 'jpToExtract')
                obj.jpToExtract = specStruct.jpToExtract;
                obj.qToExtract = specStruct.qToExtract;
            end

            % if the user passed in a specific path seq, then we probably 
            % don't want to load all the default strings
            populateDefaultStrings = 0; 
        else
            % if only one path passed in, it is assumed that it is the to
            % basepath of the exercise, then the rest is by parameter pairs
            obj.dirPathExercise =  varargin{1};
            specStruct = varargin{2};
            
            % on the other hand, passing in just the base path probably
            % mean they've passed in an options file, which then we should
            % load everything
            populateDefaultStrings = 1;
        end
        
        if strcmpi(obj.dirPathExercise(end), filesep)
            % there is a slash at the end of the dir pathing. remove it
            obj.dirPathExercise = obj.dirPathExercise(1:end-1);
        end
        
        % based on the file pathing, guess the subject number, session and
        % exercise name
        strSplitDirPathExercise = strsplit(obj.dirPathExercise, filesep);
        
        specsTemp = datasetSpecs(strSplitDirPathExercise{end-3});
        subjectDatasetName = specsTemp.dataPathSuffix;
        
        subjectId = str2num(strSplitDirPathExercise{end-2}(8:end)); % assumes the word 'subject' precedes it
        subjectSession = str2num(strSplitDirPathExercise{end-1}(8:end)); % assume the word 'session' precedes it
        subjectExerciseName = strSplitDirPathExercise{end};
        [subjectExerciseType, ~] = exerciseStringDelimit(subjectExerciseName);

        % search in the directory for the default pathing to the individual
        % files. Locate the header files if possible, given default
        % assumptions
        dirPathMocap = fullfile(obj.dirPathExercise, 'Mocap');
        if ~exist(dirPathMocap, 'dir') || ~populateDefaultStrings
            filepathDataMocap_default = [];
        else
            filepathDataMocap_default = obj.extFileSearch(dirPathMocap, constHeader);
        end
        
        dirPathImu = fullfile(obj.dirPathExercise, 'IMU'); % potentially have different path names
        dirPathImu2 = fullfile(obj.dirPathExercise, 'Shimmer');
        if (~exist(dirPathImu, 'dir') && ~exist(dirPathImu2, 'dir')) || ~populateDefaultStrings
            filepathDataImu_default = [];
        else
            % iterate through the shimmer folder to pull out all the header
            % files for all IMU devices
            if exist(dirPathImu, 'dir')
                filepathDataImu_default = obj.extFileSearch(dirPathImu, constHeader);
            elseif exist(dirPathImu2, 'dir')
                filepathDataImu_default = obj.extFileSearch(dirPathImu2, constHeader);
            end
        end
        
        dirPathEkf = fullfile(obj.dirPathExercise, 'EKF'); % potentially have different path names
        dirPathEkf2 = fullfile(obj.dirPathExercise, 'JointAngles');
        if (~exist(dirPathEkf, 'dir') && ~exist(dirPathEkf2, 'dir')) || ~populateDefaultStrings
            filepathDataEkf_default = [];
        else
            if exist(dirPathEkf, 'dir')

            elseif exist(dirPathEkf2, 'dir')
                dirPathEkf = dirPathEkf2;
            end
            
            % load the latest EKF folder
            ekfSubfolderDir = dir(dirPathEkf);
            dirPathEkf = fullfile(dirPathEkf, ekfSubfolderDir(end).name); % assume the last one in the dir is the one we want
%              dirPathEkf = fullfile(dirPathEkf, ekfSubfolderDir(3).name);
            
            filepathDataEkf_default = obj.extFileSearch(dirPathEkf, constHeader); % this one we'll use data for now
            
            if isempty(filepathDataEkf_default)
                % DEBUG some EKF data doesn't have header data right now,
                % such as healthy1. This checks specifically for that case
                filepathDataEkf_default = obj.extFileSearch(dirPathEkf, constData, 'Joint'); % this one we'll use data for now
            end
            
            if isempty(filepathDataEkf_default)
                % DEBUG some EKF data doesn't have header data right now,
                % such as healthy1. This checks specifically for that case
                jointAngleFile = searchForFileByExt(dirPathEkf, 'mat');
                filepathDataEkf_default = fullfile(dirPathEkf, jointAngleFile); % this one we'll use data for now
            end
        end
        
        dirPathSegManual = fullfile(obj.dirPathExercise, 'Segmentation_manual');
        if ~exist(dirPathSegManual, 'dir') || ~populateDefaultStrings
            filepathDataSegManual_default = [];
        else
            filepathDataSegManual_default = obj.extFileSearch(dirPathSegManual, constHeader);
        end
        
        dirPathSegCrop = fullfile(obj.dirPathExercise, 'Segmentation_cropping');
        if ~exist(dirPathSegCrop, 'dir') || ~populateDefaultStrings
            filepathDataSegCrop_default = [];
        else
            filepathDataSegCrop_default = obj.extFileSearch(dirPathSegCrop, constHeader);
        end
        
        dirPathSegAlg = fullfile(obj.dirPathExercise, 'Segmentation_algorithmic');
        if ~exist(dirPathSegAlg, 'dir') || ~populateDefaultStrings
            filepathDataSegAlg_default = [];
        else
            % load the latest alg seg folder
            algSegSubfolderDir = dir(dirPathSegAlg);
            dirPathSegAlg = fullfile(dirPathSegAlg, algSegSubfolderDir(end).name); % assume the last one in the dir is the one we want
            
            filepathDataSegAlg_default = obj.extFileSearch(dirPathSegAlg, constHeader);
        end
        
        % replace the default values with the actual values if they're
        % being passed in explicitly
        p = inputParser;
        p.KeepUnmatched = true;
 
        addOptional(p, 'datasetName', subjectDatasetName);
        addOptional(p, 'subjectName', subjectId);
        addOptional(p, 'session', subjectSession);
        addOptional(p, 'exerciseName', subjectExerciseName);
        addOptional(p, 'exerciseType', subjectExerciseType);
        
        addOptional(p, 'filepathDataMocap', filepathDataMocap_default);
        addOptional(p, 'filepathDataImu', filepathDataImu_default);
        addOptional(p, 'filepathDataEkf', filepathDataEkf_default);
        addOptional(p, 'filepathDataSegManual', filepathDataSegManual_default);
        addOptional(p, 'filepathDataSegCrop', filepathDataSegCrop_default);
        addOptional(p, 'filepathDataSegAlg', filepathDataSegAlg_default);
        addOptional(p, 'filepathDataSegGuidance', []);
        addOptional(p, 'filepathDataTorque', []);
        addOptional(p, 'filepathDataGRF', []);
        
        parse(p, specStruct); % perform the file checking
        
        % save the data passed in, or use default values
        obj.datasetName = p.Results.datasetName;
        obj.subjectNumber = p.Results.subjectName;
        obj.sessionNumber = p.Results.session;
        obj.exerciseName = p.Results.exerciseName;
        obj.exerciseType = p.Results.exerciseType;
        
        obj.filepathDataMocap = p.Results.filepathDataMocap;
        obj.filepathDataSegCrop = p.Results.filepathDataSegCrop;
        obj.filepathDataImu = sort(p.Results.filepathDataImu);
        obj.filepathDataEkf = p.Results.filepathDataEkf;
        obj.filepathDataSegManual = p.Results.filepathDataSegManual;
        obj.filepathDataTorque = p.Results.filepathDataTorque;
        obj.filepathDataGRF = p.Results.filepathDataGRF;
        obj.filepathDataSegGuidance = p.Results.filepathDataSegGuidance;
        
        % ---
        
        % legacy fields
        obj.subjectName = obj.subjectNumber;
        obj.session = obj.sessionNumber;
        
        % populate pre-canned identifier strings
        obj.subjSessExer = ['Subj' num2str(obj.subjectName) '_' ...
            'Sess' num2str(obj.session) '_' ...
            obj.exerciseName];
        
        % if there is an exerciseDescription folder, load the proper
        % exercise description for this movement
        switch obj.datasetName
            case {'healthy1', 'healthy2', 'tri1', 'stjoseph1'}
                exerciseDescPath = fullfile(obj.dirPathExercise, '..', '..', '..', 'ExerciseDescription');
                exerciseDescDir = dir(fullfile(exerciseDescPath, [subjectExerciseType(1:8) '.header']));
                if ~isempty(exerciseDescDir) && ~strcmpi(computer, 'GLNXA64')
                    % load the contents, but not if we're running on SHARCNET
                    loadHeader_exerciseDesc(obj, fullfile(exerciseDescPath, exerciseDescDir.name));
                end
        end
    end
    
    function obj = load(obj,varargin)
        % master loading function 
        
        % manually set the dt array for functions that don't have it
        switch obj.datasetName
            case {'squats_tuat_2011', 'squats_tuat_2015'}
                dt = 1/100;
                
            case 'doppel'
                dt = .037;
                
            case 'taiso_ut_2009'
                dt = 1/200;
        end
        
        if ~isempty(obj.filepathDataMocap)
            switch obj.datasetName
                case 'squats_tuat_2015'
                    % would be loaded by ekf side. no point on loading
                    % twice
                    
                case 'taiso_ut_2009'
                    dataMocapTemp = readTrc(obj.filepathDataMocap,1);
                    dataMocapTemp.dataArray = [dataMocapTemp.data.HEADF ...
                        dataMocapTemp.data.HEADR ...
                        dataMocapTemp.data.HEADL...
                        dataMocapTemp.data.RSHO...
                        dataMocapTemp.data.RELBL...
                        dataMocapTemp.data.RELBM...
                        dataMocapTemp.data.RWRISTR...
                        dataMocapTemp.data.RWRISTU...
                        dataMocapTemp.data.RMP...
                        dataMocapTemp.data.LSHO...
                        dataMocapTemp.data.LELBL...
                        dataMocapTemp.data.LELBM...
                        dataMocapTemp.data.LWRISTR...
                        dataMocapTemp.data.LWRISTU...
                        dataMocapTemp.data.LMP...
                        dataMocapTemp.data.RPEL...
                        dataMocapTemp.data.RHIP...
                        dataMocapTemp.data.RKNEEO...
                        dataMocapTemp.data.RANK...
                        dataMocapTemp.data.RHEEL...
                        dataMocapTemp.data.RPINKY...
                        dataMocapTemp.data.RTHUMB...
                        dataMocapTemp.data.LPEL...
                        dataMocapTemp.data.LHIP...
                        dataMocapTemp.data.LKNEEO...
                        dataMocapTemp.data.LANK...
                        dataMocapTemp.data.LHEEL...
                        dataMocapTemp.data.LPINKY...
                        dataMocapTemp.data.LTHUMB...
                        dataMocapTemp.data.T1...
                        dataMocapTemp.data.T7...
                        dataMocapTemp.data.L5...
                        dataMocapTemp.data.STERNUP...
                        dataMocapTemp.data.STERNLOW...
                        dataMocapTemp.data.SCAP];
                    
                    obj.dataMocap = dataMocapTemp;
                    
                    
                otherwise
                    obj.dataMocap = arsLoader(obj.filepathDataMocap);
                    obj.dataMocap.exercise_hndl = obj;
            end
        end
        
        if ~isempty(obj.filepathDataImu)
            % if there is more than 1 imu. the load list is sorted by file
            % name and will load in that sequence
            if length(obj.filepathDataImu) > 1
                obj.dataImu = imuDataHandle.empty(numel(obj.filepathDataImu),0);
                imuCounter = 0;
                for ind_imu = 1:length(obj.filepathDataImu)
                    if exist(obj.filepathDataImu{ind_imu}, 'file')
                        imuCounter = imuCounter + 1;
                        obj.dataImu(imuCounter) = arsLoader(obj.filepathDataImu{ind_imu});
                        obj.dataImu(imuCounter).exercise_hndl = obj;
                    end
                end
            else
                % just one imu
                obj.dataImu = arsLoader(obj.filepathDataImu);
                obj.dataImu.exercise_hndl = obj;
            end
        end
        
        if ~isempty(obj.filepathDataEkf) && exist(obj.filepathDataEkf, 'file')
            switch obj.datasetName
                case 'squats_tuat_2011'
                    load(obj.filepathDataEkf);
                    
                    ekfTime = 1:size(dataAngles, 1);
                    obj.dataEkf.time = ekfTime(:) * dt;
                    obj.dataEkf.Q = dataAngles(:, 4:end);
                    obj.dataEkf.dQ = [zeros(1, size(obj.dataEkf.Q, 2)); ...
                        diff(obj.dataEkf.Q)]/dt;
                    
                case 'squats_tuat_2015'
                    load(obj.filepathDataEkf);
                    
                    % load joint angle data
                    ekfTime = 1:size(q, 2);
                    obj.dataEkf.time = ekfTime(:) * dt;
                    obj.dataEkf.Q = q';
                    obj.dataEkf.dQ = dq';
                    
                    % load mocap data
                    obj.dataMocap.time = ekfTime(:) * dt;
                    
                    obj.dataMocap.dataArray = [Markers.C7 ...
                        Markers.T10 ...
                        Markers.CLAV...
                        Markers.STRN...
                        Markers.LSHO...
                        Markers.RSHO...
                        Markers.LASI...
                        Markers.RASI...
                        Markers.LTHI...
                        Markers.LKNE...
                        Markers.LTIB...
                        Markers.LANK...
                        Markers.LHEE...
                        Markers.LTOE...
                        Markers.RTHI...
                        Markers.RKNE...
                        Markers.RTIB...
                        Markers.RANK...
                        Markers.RHEE...
                        Markers.RTOE];

%                 obj.dataMocap.dataArray = [Markers.C7 ...
%                     Markers.T10 ...
%                     Markers.CLAV...
%                     Markers.STRN...
%                     Markers.LSHO...
%                     Markers.RSHO...
%                     Markers.LASI...
%                     Markers.RASI...
%                     Markers.LPSI...
%                     Markers.LTHI...
%                     Markers.LKNE...
%                     Markers.LTIB...
%                     Markers.LANK...
%                     Markers.LHEE...
%                     Markers.LTOE...
%                     Markers.RTHI...
%                     Markers.RKNE...
%                     Markers.RTIB...
%                     Markers.RANK...
%                     Markers.RHEE...
%                     Markers.RTOE...
%                     Markers.RELB...
%                     Markers.RHJC];
                    
                case 'doppel'
                    % Load data here                    
                    temp = parseCSV(obj.filepathDataEkf);
                    obj.dataEkf.time = temp.MStime/1000;

                    % Extract and individually save joint position and angle data
                    % for DOFs that will be used for repetition counting
                    % and form evaluation.                    
                    obj.dataEkf.HipRight = [temp.HipRight_x, temp.HipRight_y, temp.HipRight_z];
                    obj.dataEkf.HipLeft = [temp.HipLeft_x, temp.HipLeft_y, temp.HipLeft_z];
                    obj.dataEkf.KneeRight = [temp.KneeRight_x, temp.KneeRight_y, temp.KneeRight_z];
                    obj.dataEkf.KneeLeft = [temp.KneeLeft_x, temp.KneeLeft_y, temp.KneeLeft_z];
                    obj.dataEkf.AnkleRight = [temp.AnkleRight_x, temp.AnkleRight_y, temp.AnkleRight_z];
                    obj.dataEkf.AnkleLeft = [temp.AnkleLeft_x, temp.AnkleLeft_y, temp.AnkleLeft_z];
                    obj.dataEkf.ShoulderRight = [temp.ShoulderRight_x, temp.ShoulderRight_y, temp.ShoulderRight_z];
                    obj.dataEkf.ShoulderLeft = [temp.ShoulderLeft_x, temp.ShoulderLeft_y, temp.ShoulderLeft_z];
                    obj.dataEkf.WristRight = [temp.WristRight_x, temp.WristRight_y, temp.WristRight_z];
                    obj.dataEkf.WristLeft = [temp.WristLeft_x, temp.WristLeft_y, temp.WristLeft_z];
                    obj.dataEkf.Head = [temp.Head_x, temp.Head_y, temp.Head_z];
                    obj.dataEkf.SpineBase = [temp.SpineBase_x, temp.SpineBase_y, temp.SpineBase_z];
                    obj.dataEkf.SpineMid = [temp.SpineMid_x, temp.SpineMid_y, temp.SpineMid_z];
                    obj.dataEkf.SpineShoulder = [temp.SpineShoulder_x, temp.SpineShoulder_y, temp.SpineShoulder_z];
                    
                    %Save knee quaternion data and hip euler angle data
                    obj.dataEkf.eulHipRight = real(ExtractAngleData(temp, {'HipRight_quaternion_qx','HipRight_quaternion_qy', 'HipRight_quaternion_qz','HipRight_quaternion_qw'}));
                    obj.dataEkf.eulHipLeft = real(ExtractAngleData(temp, {'HipLeft_quaternion_qx','HipLeft_quaternion_qy', 'HipLeft_quaternion_qz','HipLeft_quaternion_qw'}));
                    obj.dataEkf.quatKneeRight = [temp.KneeRight_quaternion_qx, temp.KneeRight_quaternion_qy, temp.KneeRight_quaternion_qz, temp.KneeRight_quaternion_qw];
                    obj.dataEkf.quatKneeLeft = [temp.KneeLeft_quaternion_qx, temp.KneeLeft_quaternion_qy, temp.KneeLeft_quaternion_qz, temp.KneeLeft_quaternion_qw];
                    
                    % This is the Euler angle data
                     obj.dataEkf.rawQ = real(ExtractAngleData(temp,obj.qToExtract)); 
                     obj.dataEkf.Q = obj.dataEkf.rawQ;

                     
                     obj.dataEkf.quats = ExtractQuatData(temp,obj.qToExtract);
                     obj.dataEkf.normQ = ThetaNorm(obj.dataEkf.Q);
                    % Unwrap the joint angles data
                    %obj.dataEkf.Q = unwrap(obj.dataEkf.Q);
                    
                    % TODO: fix this to make dt accurate for varying
                    % timesteps
                    start = obj.dataEkf.time(1);
                    stop = obj.dataEkf.time(end);
                    numPoints = length(obj.dataEkf.time);
                    
                    dt = (stop-start)/numPoints;
                    
                    %Cant take angle derivative here
%                     [len wid] = size(diff(obj.dataEkf.Q));
%                     timediff = (repmat(diff(obj.dataEkf.time),1,wid));
%                     % Derivative of angle data
%                     obj.dataEkf.dQ = [zeros(1, size(obj.dataEkf.Q, 2)); ...
%                         diff(obj.dataEkf.Q)./(timediff)];

                    % This loads in the raw cartesian position data
                    %obj.dataEkf.jp = extractCartesianData1(temp);  %moreDOF
                     %obj.dataEkf.jp = extractCartesianData2(temp);  % This includes the right hip, left hip, rknee, head, and rShoulder, lshoulder
                   % obj.dataEkf.jp = extractPositionData(temp);     % This now includes the right hip, knee, ankle, shoulder, elbow, wrist, and the head. 
                    obj.dataEkf.jp = ExtractJointPositionData(temp, obj.jpToExtract);
                    %obj.dataEkf.jp = extractCartesianDataHKAonly(temp);
                    
                    
                    % Calculate the rotation theta about y-axis
                    %Theta =  ExtractThetaRotationFromShoulders(temp);
                    Theta =  ExtractThetaRotationFromHips(temp);
                    obj.dataEkf.jpTheta = Theta;
                    
                    % Save bodyIDs 
                    obj.dataEkf.bodyID = temp.body_index;
                    
                    % While all the data is loaded, form an estimate of the
                    % person's height in the units provided
                    obj.dataEkf.height = HeightEstimateAtEachTimeStep(temp)';       
                    
                    

                case 'taiso_ut_2009'                      
                    % the joint angles are actually in a folder here
                    [pathstr, name] = fileparts(obj.filepathDataEkf); 
                    newPath = fullfile(pathstr, name);
%                     dirNewPath = dir(newPath);
                    
                    loadOrder = {'Body', 'RightLeg1', 'RightLeg2', 'RightFoot' ,'LeftLeg1', ...
                        'LeftLeg2', 'LeftFoot', 'UpperBody', 'Head', 'RightArm1', ...
                        'RightArm2', 'RightHand', 'LeftArm1', 'LeftArm2', 'LeftHand'};

                    fullArray_axes = [];
                    fullArray_joint = [];
                    
                    fullArray_full = [];
                    fullArray_1dof = [];
                    for i = 1:length(loadOrder)
                        jointName = loadOrder{i};
                        jointPath = [jointName '.dat'];
                        
                        % load the file
                        jointComponentParse = dlmread(fullfile(newPath, jointPath));
                        
                        if strcmpi(jointName, 'Body')
                            dataEkf.time = jointComponentParse(:, 1);
                            dataEkf.([jointName '_cart']) = jointComponentParse(:, 2:4);
                            rotMtxData = jointComponentParse(:, 5:end);
                        else
                            rotMtxData = jointComponentParse(:, 2:end);
                        end
                        
                        % save the rot matrix data
                        dataEkf.([jointName '_rotMtx']) = rotMtxData;
                        
                        if strcmpi(jointName, 'Body')
%                             q_angle2 = reverseRotationalMatrix(rotMtxData); % this seems to introduce singularities
                            q_angle = angleAxesNotation(rotMtxData); % this seems to introduce singularities
                            q_unwrap = unwrap(q_angle);
                            q_use = q_unwrap;
                             
                        else
                            % now to deal with the joint angle data
%                             q_angle2 = reverseRotationalMatrix(rotMtxData); % this seems to introduce singularities
%                             q_unwrap = unwrap(q_angle2);
                            q_unwrap = angleAxesNotation(rotMtxData);

                            % if there's an accompanying segmentation error
                            % file, load that and apply it
                            segErrorFilePath = fullfile(obj.dirPathExercise, 'Segmentation_manual_XYZSingular', ...
                                ['SegIssues_' jointName '.data']);
                            
                            q_untangle = q_unwrap;
                            
                             if exist(segErrorFilePath, 'file')  
                                dq_untangle = [zeros(1, size(q_untangle, 2)); diff(q_untangle)]/dt;
                                
                                parseCSVsettings.skipLastEntry = 0;
                                dataSegErrors = parseCSV_string(segErrorFilePath, parseCSVsettings);
                                dataSegErrors.timeStart = dataSegErrors.timeStart/1000;
                                dataSegErrors.timeEnd = dataSegErrors.timeEnd/1000;
                                
                             end
                            
                            if exist(segErrorFilePath, 'file')  && 0
                                dq_untangle = [zeros(1, size(q_untangle, 2)); diff(q_untangle)]/dt;
                                
                                parseCSVsettings.skipLastEntry = 0;
                                dataSegErrors = parseCSV_string(segErrorFilePath, parseCSVsettings);
                                dataSegErrors.timeStart = dataSegErrors.timeStart/1000;
                                dataSegErrors.timeEnd = dataSegErrors.timeEnd/1000;
                                
                                for ind_offset = 1:length(dataSegErrors.segmentCount)
                                [~, indStart] = findClosestValue(dataSegErrors.timeStart(ind_offset), dataEkf.time);
                                [~, indEnd]  = findClosestValue(dataSegErrors.timeEnd(ind_offset), dataEkf.time);

                                switch dataSegErrors.segName{ind_offset}
                                    case 'Offset'
                                    % check each joint at the starting and
                                    % end see what the offsets look like.
                                    for ind_joints = [1 3]
                                        
                                        q_valStart = q_untangle(indStart, ind_joints);
                                        q_valEnd = q_untangle(indEnd, ind_joints);
                                        
                                        % calculate the mod offset
                                        modOffset = (q_valStart - q_valEnd) / pi;
                                        roundModOffset = round(modOffset);

                                        if abs(roundModOffset) >= 1
%                                             q_untangle(indEnd:end, ind_joints) = q_untangle(indEnd:end, ind_joints) - q_untangle(indEnd, ind_joints) + q_untangle(indStart, ind_joints);
                                            q_untangle(indEnd:end, ind_joints) = q_untangle(indEnd:end, ind_joints) + roundModOffset*pi;
                                        else
                                             lrgslj = 1;
                                        end
                                          
                                        x = [indStart indEnd];
                                        Y = q_untangle(x, ind_joints);
                                        xi = indStart:indEnd;
                                        q_interpl = interp1(x,Y,xi)';
                                        q_untangle(indStart:indEnd, ind_joints) = q_interpl;
                                    end

                                case 'Flip'
                                    ind_joints = [1 3];
                                    pointToFlipAround = repmat(q_untangle(indEnd, ind_joints), [size(q_untangle, 1) - indEnd+1, 1]);
                                    q_untangle(indEnd:end, ind_joints) = ...
                                        -(q_untangle(indEnd:end, ind_joints) - pointToFlipAround) + pointToFlipAround;
                                end
                                end
                            end
                            
                            if 0
                                tlocal = dataEkf.time;
                                h = figure;
                                plot(tlocal, q_untangle); hold on
                                plot(tlocal, q_untangle + 2*pi, 'x');
                                plot(tlocal, q_untangle + 4*pi, '*');
                                plot(tlocal, q_untangle + 6*pi, '.');
                                plot(tlocal, q_untangle - 2*pi, 'o');
                                plot(tlocal, q_untangle - 4*pi, 's');
                                plot(tlocal, q_untangle - 6*pi, '-');
                                for k = -6*pi:pi:6*pi
                                    plot([0 tlocal(end)], [k k], 'k');
                                end
%                                 h, currTimeStart, currTimeEnd, colorToUse, offset, maxY, minY)
                                plotBoxes(h, dataSegErrors.timeStart, dataSegErrors.timeEnd);
%                                 ylim([-3/2*pi 3/2*pi]);
                                title(jointName);
                            end
                            
                            if size(q_unwrap, 2) == 3
                                dofToUse = 2;
%                                 dofToUse = 1:3;
                            else
                                dofToUse = 1;
                            end
     
                            q_use = q_untangle;
                            
%                             fullArray_full = [fullArray_full rotMtxData];
%                             fullArray_full = [fullArray_full q_use(:, dofToUse)];

%                             fullArray_axes = [fullArray_axes q_use(:, 1)];
%                             fullArray_joint = [fullArray_joint q_use(:, 2:4)];

                            % drop right and left hand data since they tend
                            % to be more noisy
                            if ~strcmpi(jointName, {'LeftHand', 'RightHand'});
                                fullArray_full = [fullArray_full q_use];
                            end
                        end
                        
                        dataEkf.([jointName '_angle']) = q_use;
                    end
                    
                    dataEkf.Q_1dof = fullArray_1dof;
                    dataEkf.Q = fullArray_full;
                    dataEkf.dQ = [zeros(1, size(dataEkf.Q, 2)); ...
                        diff(dataEkf.Q)]/dt;
                    obj.dataEkf = dataEkf;
                    
                otherwise
                    obj.dataEkf = arsLoader(obj.filepathDataEkf);
            end
        end
        
        if ~isempty(obj.filepathDataSegManual) && exist(obj.filepathDataSegManual, 'file')
            switch obj.datasetName
                case 'squats_tuat_2011' 
                    parseCSVsettings.skipLastEntry = 0;
                    segData = parseCSV(obj.filepathDataSegManual, parseCSVsettings);
                    
                    % saving the proper loaded data to the obj
                    obj.dataSegManual.use = segData.Use;
                    obj.dataSegManual.segmentCount = 1:length(segData.Use);
                    obj.dataSegManual.timeStart = segData.TimeStart * dt;  % convert frames to seconds
                    obj.dataSegManual.timeEnd = segData.TimeEnd * dt;
                    
                case {'squats_tuat_2015'}
                    % load the data that doesn't con
                    parseCSVsettings.skipLastEntry = 0;
                    dataSegManualTemplate = parseCSV(obj.filepathDataSegManual, parseCSVsettings);
                    
                    dataSegManualTemplate.timeStart = dataSegManualTemplate.timeStart / 1000;  % convert ms to seconds
                    dataSegManualTemplate.timeEnd = dataSegManualTemplate.timeEnd / 1000;
                    
                    segmentManSegData = segmentationDataHandle([], []);
                    segmentManSegData.import(dataSegManualTemplate);
                    
                    obj.dataSegManual = segmentManSegData;
                   
                case {'taiso_ut_2009'}
                    % load the data that doesn't con
                    parseCSVsettings.skipLastEntry = 0;
                    dataSegManualTemp = parseCSV_string(obj.filepathDataSegManual, parseCSVsettings);
                    
                    dataSegManualTemp.timeStart = dataSegManualTemp.timeStart / 1000;  % convert ms to seconds
                    dataSegManualTemp.timeEnd = dataSegManualTemp.timeEnd / 1000;
                    
                    dataSegManualTemp.primitiveId = dataSegManualTemp.PrimId;
                    dataSegManualTemp.segmentId = dataSegManualTemp.SegId;
                    dataSegManualTemp.segmentName = dataSegManualTemp.SegName;
                    
                    segmentManSegData = segmentationDataHandle([], []);
                    segmentManSegData.import(dataSegManualTemp);
                    
                    obj.dataSegManual = segmentManSegData;                    
                    
                case 'doppel'
                    parseCSVsettings.skipLastEntry = 0;
                    segData = parseCSV_string(obj.filepathDataSegManual, parseCSVsettings);
                    
                    % saving the proper loaded data to the obj
                    obj.dataSegManual.use = ones(size(segData.TimeStart));
                    obj.dataSegManual.segmentCount = 1:length(obj.dataSegManual.use);
                    obj.dataSegManual.timeStart = segData.TimeStart /1000;  % convert frames to seconds
                    obj.dataSegManual.timeEnd = segData.TimeEnd /1000;
                    
                    obj.dataSegManual.segmentId = zeros(size(segData.TimeEnd)); % segmentid ties 'halfsegments' together. it's not necessary in your case, just placing it here for now
                 
                    % Check if these are fields first
                    if(isfield(segData, 'BodyId'))
                        obj.dataSegManual.primitiveId = segData.BodyId;
                    else
                        obj.dataSegManual.primitiveId = [];
                    end
                    if(isfield(segData, 'ExerciseType'))
                        obj.dataSegManual.segmentName = segData.ExerciseType;
                    else
                        obj.dataSegManual.segmentName = [];
                    end
                    

                    
                otherwise
                    obj.dataSegManual = arsLoader(obj.filepathDataSegManual);
            end
        end
        
        if ~isempty(obj.filepathDataSegGuidance) && exist(obj.filepathDataSegGuidance, 'file')
            switch obj.datasetName
                case 'taiso_ut_2009' 
                    % load the guidance file
                    run(obj.filepathDataSegGuidance);
                    
%                     workspaceVars = who;
                    segPrim = [];
                    for i = 1:length(motion)
%                         currVarName = workspaceVars{i};
                        eval(['segPrim(i, :) = [use_frames' num2str(motion(i)) '([1 end])];']);
                    end
                    
                    dataSegGuidance.timeStart = segPrim(:, 1) * dt;
                    dataSegGuidance.timeEnd = segPrim(:, 2) * dt;
                    dataSegGuidance.segId = motion;
                    
                    obj.dataSegGuidance = dataSegGuidance;
                    
                    if isempty(obj.dataSegManual)
                        % alter the dataSegManual if there's nothing loaded
                        % into it. load the generic file
                        pathStr = fileparts(obj.filepathDataSegGuidance);
                        baseFilePath = fullfile(pathStr, '..', '..', '..', '..', 'SegmentData', [obj.exerciseType '_ManualSegment.data']);
                        parseCSVsettings.skipLastEntry = 0;
                        dataSegManualTemplate = parseCSV_string(baseFilePath, parseCSVsettings);
                        dataSegManualTemplate.timeStart = dataSegManualTemplate.timeStart/1000;
                        dataSegManualTemplate.timeEnd = dataSegManualTemplate.timeEnd/1000;
                        
                        % now combine the datasegmanual with the
                        % datasegguidance data
                        for i = 1:length(dataSegGuidance.segId)
                            currSegId = obj.dataSegGuidance.segId(i);
                            
                            % find the corresponding segids 
                            currSegIdMatch = find(dataSegManualTemplate.SegId == currSegId);
                            currSegRampMatch = find(dataSegManualTemplate.use == 0);
                            segRampPieces = intersect(currSegIdMatch, currSegRampMatch);
                            segRampIndex = segRampPieces(1):segRampPieces(2);
                            
                            % now shift the template so it lines up with
                            % each motion                            
                            % calc the offset (want to line up the middle)
% % %                             lengthGuidance = dataSegGuidance.timeEnd(i) - dataSegGuidance.timeStart(i);
% % %                             lengthSeg = dataSegManualTemplate.timeEnd(segRampPieces(2)) - ...
% % %                                 dataSegManualTemplate.timeStart(segRampPieces(1));
% % %                             offset = (dataSegGuidance.timeStart(i) + lengthGuidance/2) + ...
% % %                                 -(dataSegManualTemplate.timeStart(segRampPieces(1)) + lengthSeg/2);

                            % calc the offset (want to line up the end)
                            offset = (dataSegGuidance.timeEnd(i)) + ...
                                -(dataSegManualTemplate.timeEnd(segRampPieces(2)));

                            dataSegManualTemplate.timeStart(segRampIndex) = ...
                                dataSegManualTemplate.timeStart(segRampIndex) + offset;
                            dataSegManualTemplate.timeEnd(segRampIndex) = ...
                                dataSegManualTemplate.timeEnd(segRampIndex) + offset;
                            
                            % for all the segments that is outside the
                            % boundaries (for both inside and out), declare
                            % them invalid
                            valuesTooSmall = find(dataSegManualTemplate.timeStart(segRampIndex) < dataSegGuidance.timeStart(i));
                            valuesTooLarge = find(dataSegManualTemplate.timeEnd(segRampIndex) > dataSegGuidance.timeEnd(i));
                            valuesInvalid = segRampIndex([valuesTooSmall valuesTooLarge]);
                            
                            dataSegManualTemplate.use(valuesInvalid) = 0;
                        end
                        
                        obj.dataSegManual = dataSegManualTemplate;
                    end
            end
            
        end
        
        if ~isempty(obj.filepathDataSegCrop) && exist(obj.filepathDataSegCrop, 'file')
            obj.dataSegCrop = arsLoader(obj.filepathDataSegCrop);
            
            if ~isempty(obj.dataSegCrop)
                switch obj.datasetName
                    % all these motions won't conform to the template. time
                    % zero starts at the start of the file and it's to
                    % ambigious, so we should explicitly modify them here
                    case {'squats_tuat_2011', 'squats_tuat_2015', 'taiso_ut_2009'}
                        obj.dataSegCrop.timeStart = obj.dataSegCrop.timeStart/1000;
                        obj.dataSegCrop.timeEnd = obj.dataSegCrop.timeEnd/1000;
                        
                    case 'doppel'

                end
            end
        end
        
        if ~isempty(obj.filepathDataSegAlg) && exist(obj.filepathDataSegAlg, 'file')
            obj.dataSegAlg = arsLoader(obj.filepathDataSegAlg);
        end
        
        if ~isempty(obj.filepathDataGRF) && exist(obj.filepathDataGRF, 'file')
            switch obj.datasetName
                 case 'squats_tuat_2015'
                     load(obj.filepathDataGRF);
                     obj.dataForces = FP;
                     
                case 'taiso_ut_2009'
                    force_struct = readForce(obj.filepathDataGRF);
                    
                    FP.time = force_struct.data.Sample/force_struct.SampleRate;
                    FP.P  = [force_struct.data.X1  force_struct.data.Y1  force_struct.data.Z1 ...
                        force_struct.data.X2  force_struct.data.Y2  force_struct.data.Z2];
                    FP.F = [force_struct.data.FX1 force_struct.data.FY1 force_struct.data.FZ1 ...
                        force_struct.data.FX2 force_struct.data.FY2 force_struct.data.FZ2];
                    FP.M = [force_struct.data.MZ1 ...
                        force_struct.data.MZ2];
                    
                    obj.dataForces = FP;
            end
        end        

        if ~isempty(obj.filepathDataTorque) && exist(obj.filepathDataTorque, 'file')
             switch obj.datasetName
                 case 'squats_tuat_2015'
                     load(obj.filepathDataTorque);
                     obj.dataForces.jointTorque = GAMMA';
             end
        end
        
        %In some cases the patient file specifies operation on left leg but
        %imu names were always Waist RKnee RAnkle so here we rename those
        %caes to LKnee and LAnkle
        
        if isfield(obj.patient_hndl,'surgicalSide') && numel(obj.dataImu) == 3 && strcmp(obj.patient_hndl.surgicalSide,'L')
           
           %Gotta rename the IMUs
           for i=1:numel(obj.dataImu)
               index = strfind(obj.dataImu(i).name,'R');
              if(~isempty(index))
                  obj.dataImu(i).name(index) = 'L';
              end
           end
            
        end
        
        
    end
    
    function h = plot(obj)
        colourCrop = 'k';
        colourSegmentGood = 'g';
        colourSegmentBad = 'r';
        
        h = figure;
        
        timeToPlot = obj.dataEkf.time;
        dataToPlot = obj.dataEkf.Q;
        veloToPlot = obj.dataEkf.dQ;
        
        % pull out the cropping results
        if ~isempty(obj.dataSegCrop)
            cropValStart = obj.dataSegCrop.timeStart;
            cropValEnd = obj.dataSegCrop.timeEnd;
        else
            cropValStart = [];
            cropValEnd = [];
        end
            
        % and segmentation results
        if ~isempty(obj.dataSegManual)
            algValStart = obj.dataSegManual.timeStart;
            algValEnd = obj.dataSegManual.timeEnd;
            useArray = find(obj.dataSegManual.use);
            useNotArray = setxor(1:length(algValStart), useArray);
        else
            algValStart = [];
            algValEnd = [];
        end
        
        % plotting joint angles
        h1 = subplot(2, 1, 1);
        plot(timeToPlot, dataToPlot);
        
        hold on
        
        h_t = title([obj.datasetName '_subj' num2str(obj.subjectName) ...
                '_sess' num2str(obj.session) ...
                '_' obj.exerciseName]);
        set(h_t, 'Interpreter', 'none')

        ylabel('Joint angles [rad]');    
        
        % and cropping/segmentation
        if ~isempty(cropValStart)
            plotBoxes(h, cropValStart, cropValEnd, colourCrop, 0);
        end
        
        if ~isempty(algValStart)
            plotBoxes(h, algValStart(useArray), algValEnd(useArray), colourSegmentGood, 0.01);
            plotBoxes(h, algValStart(useNotArray), algValEnd(useNotArray), colourSegmentBad, 0.01);
        end
        
        % now plotting joint velocity
        h2 = subplot(2, 1, 2);
        plot(timeToPlot, veloToPlot);
        
        ylabel('Joint velo [rad]');
        
        if ~isempty(cropValStart)
            plotBoxes(h, cropValStart, cropValEnd, colourCrop, 0);
        end
        
        if ~isempty(algValStart)
            plotBoxes(h, algValStart(useArray), algValEnd(useArray), colourSegmentGood, 0.01);
            plotBoxes(h, algValStart(useNotArray), algValEnd(useNotArray), colourSegmentBad, 0.01);
        end
        
        linkaxes([h1, h2], 'x');
        
        xlabel('Time [s]');
    end
    
    function [timeStart, timeEnd] = cropTime(obj,cropType,i)
        if ~exist('cropType', 'var')
            cropType = 'any';
        end
        
        if ~exist('i', 'var')
            i = 1;
        end
        
        if ~isempty(obj(i).dataSegCrop) && (strcmpi(cropType, 'any') || strcmpi(cropType, 'segCrop'))
            timeStart = obj(i).dataSegCrop.timeStart;
            timeEnd = obj(i).dataSegCrop.timeEnd;
            
        elseif ~isempty(obj(i).dataSegManual)
            tol = 5; % crop with a 5 second gap
            timeStart = obj(i).dataSegManual.timeStart(1) - tol;
            timeEnd = obj(i).dataSegManual.timeEnd(end) + tol;
            
        else
            fprintf('No cropping data loaded \n');
            timeStart = [];
            timeEnd = [];
        end
    end
    
    function obj = cropData(obj,cropType)
        % apply the cropping segmentation to each data sequence available
        if ~exist('cropType', 'var')
            cropType = 'any';
        end
        
        for i=1:numel(obj)
            [timeStart, timeEnd] = cropTime(obj,cropType,i);
            if isempty(timeStart)
                fprintf('No cropping data loaded \n');
                return
            end

            if ~isempty(obj(i).dataMocap)
                obj(i).dataMocap.cropData(timeStart, timeEnd);
            end

            if ~isempty(obj(i).dataImu)
                for ind = 1:length(obj(i).dataImu)
                    obj(i).dataImu(ind).cropData(timeStart, timeEnd);
                end
            end

            if ~isempty(obj(i).dataEkf)
                obj(i).dataEkf.cropData(timeStart, timeEnd);
            end

            % no cropping should be applied to the segment data
        end
    end
    
    function obj = loadHeader_exerciseDesc(obj, exerciseDescHeaderPath)
        
        % parse the XML file into a structure
        xDoc = parseXML(exerciseDescHeaderPath);
        
        % pull the proper data from the base layer
        for ind_attributes = 1:length(xDoc.Attributes)
            xmlName = xDoc.Attributes(ind_attributes).Name;
            xmlValue = xDoc.Attributes(ind_attributes).Value;
            
            switch xmlName
                case 'short'
                    
                case 'long'
                    obj.exerciseNameLong = xmlValue;
            end
        end
        
        for ind_attributes = 1:length(xDoc.Children)
            xmlName = xDoc.Children(ind_attributes).Name;
            xmlData = xDoc.Children(ind_attributes).Data;
            xmlChild = xDoc.Children(ind_attributes).Children;
            
            % sometimes the xmlChild will be empty if the attribute itself
            % is empty, causing an unexpected struct situation
            if isempty(xmlChild)
                xmlChild.Data = [];
            end
            
            switch xmlName
                case '#text'
                    if sum(isspace(xmlData)) > 0
                        % parsed a blank. do nothing. not sure why this
                        % happens
                    end
                    
                case 'kinematicDirection'
                    obj.kinematicDirection = xmlChild.Data; % the child data is parsed as a string, so this converts it back to an array
                    
                case 'initPosture'
                    obj.initPosture = xmlChild.Data;
                    
                case 'description'
                    obj.description = xmlChild.Data;
            end
        end
    end
end % methods

methods(Static)
    function fileExtList = extFileSearch(dirPath, extToLocate, prefixToLocate)
        % given a directory path, search its contents for all .[ext] (some
        % extension). The likely usage of this is to search for .header and
        % .data files for file pathing purposes. fileExtList will be
        % returned as a string, unless there is multiple entries of a given
        % file found, in which case it would be returned as a 
        
        if ~exist('prefixToLocate', 'var')
            prefixToLocate = [];
        end
        
        fileExtList = {};
        fileExtCounter = 0;
        dirPathDir = dir(dirPath);
        for ind_dirPath = 1:length(dirPathDir)
            currFile = fullfile(dirPath, dirPathDir(ind_dirPath).name);
            [pathstr, name, ext] = fileparts(currFile);
            
            if strcmpi(extToLocate, ext) && ...
                    (isempty(prefixToLocate) || strcmpi(name(1:length(prefixToLocate)), prefixToLocate))
                fileExtCounter = fileExtCounter + 1;
                fileExtList{fileExtCounter} = currFile;
            end
        end
        
        if fileExtCounter == 1
            fileExtList = fileExtList{1};
        end
    end
end
end % classdef