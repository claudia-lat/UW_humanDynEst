function fp_calib_getWeight
    % defining the calibration matrix, as is from the AMTI calibration files
    % FP1 (left) = 0541
    % FP2 (right) = 0561
    
    % loading the test data
    subjectNumber = '03';
    fileLoad1 = ['D:\aslab\data\Fullbody_IIT_2017\Subject' subjectNumber '\mocap_fp\subject_weight_fp1.anc'];
    fileLoad2 = ['D:\aslab\data\Fullbody_IIT_2017\Subject' subjectNumber '\mocap_fp\unloaded_fp1.anc'];
    
    % start procedures
    fp = fp_calibration(fileLoad1, fileLoad2);
    
    % calculate mean weight
    meanVal = mean(fp.F1_kg(end-100:end, 3));
    
    % plot the results
    figure;
    plot([fp.F1_kg(:, 1:3)]); ylabel('Cortex kgs'); title(['kg_z1 = ' num2str(meanVal)]);
end