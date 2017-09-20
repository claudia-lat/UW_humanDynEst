function fptesting
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
    fileLoad = 'data\2017-09-14_TimeSyncTest\timesync1.anc';
    fId = fopen(fileLoad);
    for i = 1:11
        % remove header data that Cortex inserts
        fgetl(fId);
    end
    data = textscan(fId,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f','delimiter','\t');
    F1XAB = data{1};
    F1YBD = data{2};
    F1YAC = data{3};
    F1XDC = data{4};
    F1ZA = data{5};
    F1ZB = data{6};
    F1ZC = data{7};
    F1ZD = data{8};
    F2XAB = data{9};
    F2YBD = data{10};
    F2YAC = data{11};
    F2XDC = data{12};
    F2ZA = data{13};
    F2ZB = data{14};
    F2ZC = data{15};
    F2ZD = data{16};

    % restack the array in the same layout as the AMTI calib mtx
    F1_adc = [F1ZC F1ZD F1ZA F1ZB F1YAC F1XDC F1XAB F1YBD];
    F2_adc = [F2ZC F2ZD F2ZA F2ZB F2YAC F2XDC F2XAB F2YBD];
        
    % setting up conversion factors
    analogToVoltFactor = (2^16)/20; % analog units to voltage

    [F1_volt, F1_lb] = calibrateFPdata(F1_adc, FP1_calib, analogToVoltFactor);
    [F2_volt, F2_lb] = calibrateFPdata(F2_adc, FP2_calib, analogToVoltFactor);

    h1 = figure;
    h2 = figure;
    h3 = figure;

    figure(h1); subplot(211); plot(F1_adc); title('adc'); subplot(212); plot(F2_adc);
    figure(h2); subplot(211); plot(F1_volt); title('voltage'); subplot(212); plot(F2_volt);
    figure(h3); subplot(211); plot(F1_lb(:, 1:3)); title('lbs'); subplot(212); plot(F2_lb(:, 1:3));
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