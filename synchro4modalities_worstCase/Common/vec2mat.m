function state_array = vec2mat(state_vector, feature_count)
    % this function converts a vector form 'state_vector' into a matrix,
    % given that we know what the statecount (the width of the matrix) a
    % priori. it is designed to be used in conjunction with vec2mat to 
    % allow for easy conversion between the two forms
    
    state_array = reshape(state_vector, feature_count, size(state_vector, 1)/feature_count); % size(2), size(1)
end

