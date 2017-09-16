function [shapehand, cortex] = loadDatagloveData_mat(targetPath)
    % load shapehand kinematic information from cortex SDK output
    % 1:3 is offset
    % 4:6 is rot 
    % 7 is bone length
    
    load(targetPath);

    % combine the two arrays
    names = fieldnames(cortex);
    for i=1:numel(names)
        shapehand.(names{i}) = cortex.(names{i});
    end
    
    % convert all factors to rad
    names = fieldnames(shapehand);
    for i=1:numel(names)
        if strcmpi(names{i}, 'frame') || strcmpi(names{i}, 'time') || ...
                strcmpi(names{i}, 'gen') || strcmpi(names{i}, 'hand') || ...
                strcmpi(names{i}, 'wrist_lat') || strcmpi(names{i}, 'wrist_rad') || ...
                strcmpi(names{i}, 'elbow_lat') || strcmpi(names{i}, 'elbow_rad') || ...
                strcmpi(names{i}, 'wrist') || strcmpi(names{i}, 'elbow')
            % don't convert these
            
        else
            shapehand.(names{i}) = shapehand.(names{i}) * (pi/180);
        end
    end
    
    shapehand = cleanRepeatedTimestamps(shapehand);
    
%     % shift to seconds
    shapehand.time = shapehand.time / 1000;
end

function dataStruct = cleanRepeatedTimestamps(dataStruct)
    rescale = 1;
    
    newTimeOut = dataStruct.time;

    if rescale
        emgTimeS = newTimeOut/1000';
        emgDt = floor(1/mean(diff(emgTimeS)));
        
        % ensure uniqueness in x time array
        [x,IA,IC] = unique(emgTimeS);
        xx = (emgTimeS(2):1/emgDt:emgTimeS(end-1))';
        
        names = fieldnames(dataStruct);
        for i=1:numel(names)
            if ~isempty(dataStruct.(names{i}))
                y = dataStruct.(names{i})(IA, :);
                newDataOut = interp1(x, y, xx, 'linear');
                dataStruct.(names{i}) = newDataOut;
            else
                
            end
        end
        
        newTimeOut = xx*1000;
    end
end