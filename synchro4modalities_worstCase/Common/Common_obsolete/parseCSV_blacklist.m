%better read
function data = parseCSV_blacklist(path)

fid = fopen(path);

fdata = fread(fid,inf,'uint8=>char');

% if this breaks, try using {\r\n|\n} for expression
flines = regexp(fdata','(\r)?\n','split');
headers = regexp(flines{1},',','split');

end_comma = false;
if(flines{1}(end) == ',')
    end_comma = true;
    headers = headers(1:end-1);    
end

format = [];
uncalibrated_index = [];
for i=1:numel(headers)
    format = strcat(format,'%s,');
end

if ~end_comma
    format = format(1:end-1);
end

num_els = numel(headers);
data_mat = cell(numel(flines)-1,num_els);

row = 0;
for i=2:numel(flines)
    if(isempty(flines{i}))
        break;
    end
    
    currLine = regexp(flines{i},',','split');
    for j = 1:numel(headers)
        data_mat{i-1, j} = currLine{j};
    end
    row = row+1;
end

data_mat = data_mat(1:row,:);
cells = mat2cell(data_mat,row,ones(1,numel(headers)));
data = cell2struct(cells,headers,2);
fclose(fid);
end

