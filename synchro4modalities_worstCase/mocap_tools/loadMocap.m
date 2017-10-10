function data = loadMocap(filepath_mocap)
    scanStr = '%f%f';
    for ind_data = 1:80
        scanStr = [scanStr '%f%f%f'];
    end

    fid = fopen(filepath_mocap);
    data = textscan(fid,scanStr,'HeaderLines',6,'Delimiter','/t');
    data = [data{:}];
    fclose(fid);
end