for ind_subjects = 1:size(filepath_subject)
for ind_files = 1:size(filelist{1})
    filepath_mocap = [filepath_base filepath_subject filelist{1}{ind_files}];
    filepath_fp    = [filepath_base filepath_subject filelist{2}{ind_files}];

    filepath_mvn        = [filepath_base filepath_subject filelist{3}{ind_files}];
    filepath_san_left   = [filepath_base filepath_subject filelist{4}{ind_files}];
    filepath_san_right  = [filepath_base filepath_subject filelist{5}{ind_files}];

    filepath_output     = [filepath_base filepath_subject filelist{6}{ind_files}];
    filepath_output_mvn          = [filepath_output '_mvn.mat'];
    filepath_output_sandalsLeft  = [filepath_output '_sandalsLeft.mat'];
    filepath_output_sandalsRight = [filepath_output '_sandalsLeft.mat'];
    filepath_output_mocap        = [filepath_output '_mocap.mat'];
    filepath_output_fp           = [filepath_output '_fp.mat'];
    
    filepath_output_fig       = [filepath_output '.fig'];
    
    %% extracting data and aligning
    % --------- xsens ---------
    % read 
    if exist(filepath_mvn, 'file') && (~exist(filepath_output_mvn, 'file') || overwrite)
        mvn_raw = xml_read(filepath_mvn);

        % time alignment
        startTime = mvn_raw.subject.frames.frame(4).ATTRIBUTE.ms;
    else
        mvn_raw = [];
        startTime = 0;
    end
    
    % --------- left sandal ---------
    % read
    if exist(filepath_sandals, 'file') && (~exist(filepath_output_sandalsLeft, 'file') || overwrite)
        sandalsLeft_raw = dlmread(filepath_san_left , ' ');
        
        % --------- right sandal ---------
        % read
        sandalsRight_raw = dlmread(filepath_san_right , ' ');
           else
        sandalsRight_raw = [];
        sandalsLeft_raw = [];
    end
    
    % --------- mocap ---------
    % read
    if exist(filepath_mocap, 'file') && (~exist(filepath_output_mocap, 'file') || overwrite)
        mocap_raw = readTrc(filepath_mocap);
        
        % calibrate
        mocap_raw.data.Time = mocap_raw.data.Time / 1000 + startTime;
    else
        mocap_raw = [];
    end
    
    % --------- forceplates ---------
    if exist(filepath_fp, 'file') && (~exist(filepath_output_fp, 'file') || overwrite)
        % read
        fp_raw = loadFp_calibrate(filepath_fp, []);
        
        % calibrate and save
        fp_raw.data.Time = fp_raw.data.Time / 1000 + startTime;
        
    else
        fp_raw = [];
    end
    
    %% save all the contents
    [pathstr,name,ext] = fileparts(filepath_mat_output);
    
    if ~exist(pathstr, 'dir')
        mkdir(pathstr)
    end

    if ~isempty(mvn_raw)
        save(filepath_output_mvn, 'mvn_raw');
    end
    
    if ~isempty(sandalsLeft_raw)
        save(filepath_output_sandalsLeft, 'sandalsLeft_raw');
    end
    
    if ~isempty(sandalsRight_raw)
        save(filepath_output_sandalsRight, 'sandalsRight_raw');
    end
    
    if ~isempty(mocap_raw)
        save(filepath_output_mocap, 'mocap_raw');
    end
    
    if ~isempty(fp_raw)
        save(filepath_output_fp, 'mvn_raw');
    end

end
end

