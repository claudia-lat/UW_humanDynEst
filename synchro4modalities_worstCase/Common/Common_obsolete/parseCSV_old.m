function data = parseCSV(path)

fid = fopen(path);

%Read First Line
tline = fgets(fid);

commaCheckLoop = 1;
while commaCheckLoop
    if isempty(regexp(tline(end),'[A-Za-z0-9]','end'))
        tline = tline(1:end-1);
    else
        commaCheckLoop = 0;
    end
end

%Save Headers
headers = regexp(tline,',','split');

%Number of elements per line, -1 because we have a , at the end (JL removed
%in favour of regex parse at 'commaCheckLoop')
num_els = numel(headers);
headers = headers(1:num_els);

%Number of lines in the file excluding the header
nLines = 0;
while (fgets(fid) ~= -1),
  nLines = nLines+1;
end

cells = cell(1,num_els);
for i=1:num_els
    cells{i} = zeros(nLines,1);
end
data = cell2struct(cells,headers,2);


%Move seek to second line
fseek(fid,0,'bof');
%Skip header string again 
fgets(fid);

for i=1:nLines
    tline = fgets(fid);
    str_data = regexp(tline,',','split');
    for j=1:num_els
        if(~isempty(find(str_data{j}=='x',1)))
           %Hex string
           data.(headers{j})(i) = typecast(uint32(sscanf(str_data{j},'%li')),'int32');
        else
            %Data String
            data.(headers{j})(i) = sscanf(str_data{j},'%f');
        end
    end
end

%Close file
fclose(fid);
end