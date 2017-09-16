function writeCSV(file,data)
    fid = fopen(file,'w');

    names = fieldnames(data);
    r = numel(data.(names{1}));
    
    uncalibrated_index = zeros(1,numel(names));
    for j=1:numel(names)
        if(~isempty(strfind(names{j},'uncalibrated')))
            data.(names{j}) = typecast(int32(data.(names{j})),'uint32');
            uncalibrated_index(j) = 1;
<<<<<<< .mine
        elseif (~isempty(strfind(names{j},'Frame')))
            format = strcat(format,'%u,'); % write them without decimal points since they usually don't have that level of precision
        elseif (~isempty(strfind(names{j},'SystemMSTimeStamp')))
            format = strcat(format,'%u,'); % write them without decimal points since they usually don't have that level of precision
        else
            format = strcat(format,'%f,');
=======
>>>>>>> .r1689
        end
    end
    
    format = strcat(format, '\r\n');
    
    c = struct2cell(data);
    mu = cell2mat(c(uncalibrated_index==1)');
    m = cell2mat(c(uncalibrated_index==0)');
    
%     format = cell(1,numel(names));
    if(isempty(mu))
<<<<<<< .mine
        mat = m;
%         format(uncalibrated_index==0) = {'%f,'};
=======
        format(:) = {'%f,'};
>>>>>>> .r1689
    elseif(isempty(m))
<<<<<<< .mine
        mat = mu;
%         format(uncalibrated_index==1) = {'%0x%08x,'};
=======
        format(:) = {'0x%08x,'};
>>>>>>> .r1689
    else
        format(1:size(m,2)) = {'%f,'};
        format(size(m,2)+1:size(m,2)+size(mu,2)) = {'0x%08x,'};
    end
%         format = [format{:} '\r\n'];
    
    fprintf(fid,'%s%s\r\n',sprintf('%s,',names{uncalibrated_index==0}),sprintf('%s,',names{uncalibrated_index==1}));
    if(isempty(mu))
        for i=1:r
            fprintf(fid,format,m(i,:));
        end
    elseif(isempty(m))
        for i=1:r
            fprintf(fid,format,mu(i,:));
        end
    else
        for i=1:r
            fprintf(fid,format,m(i,:),mu(i,:));
        end
    end
    
    fclose(fid);
end
