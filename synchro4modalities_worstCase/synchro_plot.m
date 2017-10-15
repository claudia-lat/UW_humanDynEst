for ind_subjects = 1:size(filepath_subject)
for ind_files = 1:size(filelist{1})
    filepath_output_mvn          = [filepath_output '_mvn.mat'];
    filepath_output_sandalsLeft  = [filepath_output '_sandalsLeft.mat'];
    filepath_output_sandalsRight = [filepath_output '_sandalsLeft.mat'];
    filepath_output_mocap        = [filepath_output '_mocap.mat'];
    filepath_output_fp           = [filepath_output '_fp.mat'];
    
    filepath_output_fig       = [filepath_output '.fig'];
    filepath_output_png       = [filepath_output '.png'];
    
        %% extracting data and aligning
    % --------- xsens ---------
    % read 
    if exist(filepath_output_mvn, 'file')
        mvn_raw = load(filepath_output_mvn);
        
        % calibrate and save
        mvnTime = [];
        mvnPos = [];
        for ind_data = 4:length(data_raw.mvn.subject.frames.frame)
            currTime = (data_raw.mvn.subject.frames.frame(ind_data).ATTRIBUTE.ms / 1000) - startTime;
            currPos = data_raw.mvn.subject.frames.frame(ind_data).position;
            mvnTime = [mvnTime; currTime];
            mvnPos =  [mvnPos;  currPos];
        end
        
        mvn_calib.time = mvnTime/ 1000;
        mvn_calib.data = mvnPos;
    else
        mvn_calib = [];
    end
    
    % --------- left sandal ---------
    % read
    if exist(filepath_output_sandalsLeft, 'file')
        sandalsLeft_raw = load(filepath_output_sandalsLeft);
        
        % --------- right sandal ---------
        % read
        sandalsRight_raw = load(filepath_output_sandalsRight);
    else
        sandalsRight_calib = [];
        sandalsLeft_calib = [];
    end
    
    % --------- mocap ---------
    % read
    if exist(filepath_output_mocap, 'file')
        mocap_raw = load(filepath_output_mocap);
        
         mocap_calib.time = mocap_raw.data.Time / 1000;
    mocap_calib.data = mocap_raw.data;
           else
 mocap_calib = [];
    end
    
    % --------- forceplates ---------
    if exist(filepath_output_fp, 'file')
        % read
        fp_raw = load(filepath_output_fp);
        
         fp_calib.time = fp_raw.data.Time / 1000;
    fp_calib.data = fp_raw.data;
    else
        fp_raw = [];
    end
    
    %% plotting data
    h0 = figure;
    h1 = subplot(221);
    plot(mvn_calib.time, mvn_calib.data, '.');
    title('mvn');

    h2 = subplot(222);
%     plot(data_calib.sandals_right.time, data_calib.sandals_right.data, '.'); hold on
%     plot(data_calib.sandals_left.time,  data_calib.sandals_left.data, '.');
    title('sandal right+left');

    h3 = subplot(223);
    plot(mocap_calib.time, mocap_calib.data.EL_LAT, '.');
    title('mocap');

    h4 = subplot(224);
    plot(fp_calib.time, fp_calib.F1, '.');
    title('fp [N]');
    linkaxes([h1 h2 h3 h4], 'x');
    
    %% save all the contents
    [pathstr,name,ext] = fileparts(filepath_output_fig);
    
    if ~exist(pathstr, 'dir')
        mkdir(pathstr)
    end

    saveas(h0, filepath_output_fig);
        saveas(h0, filepath_output_png);
end
end

