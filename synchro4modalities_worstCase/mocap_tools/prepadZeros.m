function outString = prepadZeros(inString, targetLength)
    if isnumeric(inString)
        % if is a number, convert it to string
        inString = num2str(inString);
    end

    if strcmpi(inString, 'missing')
        % if it's just 'missing', set it to nothing
        inString = '';
    end

    if size(inString, 2) == 0
        % if there's nothing passed in, return null
        outString = [];
    else
        % otherwise, prepad it according to the targetLength
        outString = inString;
        for i = (size(inString, 2)+1):targetLength
            outString = ['0' outString];
        end
    end
end