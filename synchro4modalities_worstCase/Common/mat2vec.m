function [state_vector, feature_count] = mat2vec(state_array)
    % this function converts a matrix form 'state_array' into a vector form
    % 'state_vector'. it is designed to be used in conjunction with
    % 'vec2mat' to allow for easy conversion between the two forms
    
    feature_count = size(state_array, 1);
    state_vector = reshape(state_array, size(state_array, 2)*size(state_array, 1), 1);
end