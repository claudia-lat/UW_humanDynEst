function localTesting
    % defining the calibration matrix, as is from the AMTI calibration files
    % FP1 = 0541
    % FP2 = 0561

    FP1_calib = [0.1857718	-0.1510818	0.2560428	-0.2383812	0.3552629	-11.8969181	11.8100539	0.3578005
    -0.7145054	-0.3994613	0.1534758	0.452656	11.5410966	-0.1482715	0.1471889	11.6235325
    -24.0784063	-24.5258619	-24.1982515	-24.2939251	-0.3326175	-0.0151676	0.1636783	0.1749859
    173.1750103	175.2073443	-171.8125152	-174.1176904	0	0	0	0
    180.4522012	-181.6292807	180.1535382	-180.2768301	0	0	0	0
    -1.7264629	-1.7585462	-1.735056	-1.7419159	122.264218	-122.6549011	-121.7593482	-123.1375287];

    FP2_calib = [0.3119342	-0.3027807	0.4253523	-0.0834534	0.3247007	-11.6861478	11.6962775	0.3193138
    -0.7610162	-0.3878758	0.6419344	0.6092338	11.7931326	0.0639227	-0.0639781	11.5974797
    -23.8892571	-23.6714047	-24.3150895	-23.5307501	-0.3019417	-0.0247871	-0.0251555	-0.0965701
    173.2423527	170.311134	-170.8479385	-167.1206904	0	0	0	0
    179.1098509	-173.5546663	181.7210017	-174.9241195	0	0	0	0
    -1.5781653	-1.5637736	-1.6062965	-1.5544817	122.4718391	-120.9667541	-121.0716099	-120.4399804];

    % loading the test data
    fileLoad = 'data\amtitest1.anc';
    [cortex_time, cortex_f1_adc, cortex_f2_adc] = loadFPDataCortex(fileLoad);
    
    % setting up conversion factors
    analogToVoltFactor = (2^16)/20; % analog units to voltage
    
    [F1_volt, F1_lb] = calibrateFPdata(cortex_f1_adc, FP1_calib, analogToVoltFactor);
    [F2_volt, F2_lb] = calibrateFPdata(cortex_f2_adc, FP2_calib, analogToVoltFactor);
    
    % loading the test data
    fileLoad = 'data\DSADATA00001.txt';
    [amtiTime, amti_f1_lb, amti_f2_lb] = loadFPDataNetForce(fileLoad);
        
%     h3 = figure;
%     figure(h3); subplot(211); plot(F1_lb(:, 1:3)); title('Cortex lbs'); subplot(212); plot(F2_lb(:, 1:3));
%     
%      h2 = figure;
%     figure(h2); subplot(211); plot(amti_f1_lb(:, 1:3)); title('Amti lbs'); subplot(212); plot(amti_f2_lb(:, 1:3));

 figure; 
 subplot(211); plot([F1_lb(:, 1:3) F2_lb(:, 1:3)]); title('Cortex lbs'); 
 subplot(212); plot([amti_f1_lb(:, 1:3) amti_f2_lb(:, 1:3)]);  title('Netforce lbs'); 
end

function [F1_volt, F1_lb] = calibrateFPdata(F1_adc, FP1_calib, analogToVoltFactor)
    % converting from bits to voltage, and removing offset
    F1_volt = F1_adc / analogToVoltFactor; % ADC to voltage
    F1_volt = F1_volt - repmat(F1_volt(1, :), size(F1_volt, 1), 1); % remove offset

    % apply calibration matrix
    F1_calib = [];
    for i = 1:size(F1_adc, 1)
        rawDataRow = F1_volt(i, :);
        calibDataRow = FP1_calib*rawDataRow';
        F1_calib = [F1_calib; calibDataRow'];
    end

    F1_lb = F1_calib;
end

function [time, fp1, fp2] = loadFPDataCortex(fileLoad)
    fId = fopen(fileLoad);
    for i = 1:11
        % remove header data that Cortex inserts
        fgetl(fId);
    end
    data = textscan(fId,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f','delimiter','\t');
    fclose(fId);
    
    time = data{1};
    F1XAB = data{2};
    F1YBD = data{3};
    F1YAC = data{4};
    F1XDC = data{5};
    F1ZA = data{6};
    F1ZB = data{7};
    F1ZC = data{8};
    F1ZD = data{9};
    F2XAB = data{10};
    F2YBD = data{11};
    F2YAC = data{12};
    F2XDC = data{13};
    F2ZA = data{14};
    F2ZB = data{15};
    F2ZC = data{16};
    F2ZD = data{17};

    % restack the array in the same layout as the AMTI calib mtx
    fp1 = [F1ZC F1ZD F1ZA F1ZB F1YAC F1XDC F1XAB F1YBD];
    fp2 = [F2ZC F2ZD F2ZA F2ZB F2YAC F2XDC F2XAB F2YBD];
end

function [time, fp1, fp2] = loadFPDataNetForce(fileLoad)
    data = csvread(fileLoad);
    
    time = [];
    Fx1 = data(:, 1);
    Fy1 = data(:, 2);
    Fz1 = data(:, 3);
    Mx1 = data(:, 4);
    My1 = data(:, 5);
    Mz1 = data(:, 6);
    Fx2 = data(:, 7);
    Fy2 = data(:, 8);
    Fz2 = data(:, 9);
    Mx2 = data(:, 10);
    My2 = data(:, 11);
    Mz2 = data(:, 12);
    
    fp1 = [Fx1 Fy1 Fz1 Mx1 My1 Mz1];
    fp2 = [Fx2 Fy2 Fz2 Mx2 My2 Mz2];
end