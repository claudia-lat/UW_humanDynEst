function [myoFeature, ClockWindowed] = calculateEMGFeatures(subjMyo, featureNumber, subjTime)
    try
        [Feature, ClockWindowed] = CalculateFeatures_PerWindow(subjMyo.emgDataInterpol, ...
            subjMyo.emgTimeInterpol, featureNumber, subjMyo.windowSize, subjMyo.windowOverlap, subjMyo.normMethod);
        %     myoFeature = spline(ClockWindowed', Feature', subjTime')';
        myoFeature = Feature;
    catch err
        fprintf(': Error in calculateEMGFeatures (feat %u): %s\n', featureNumber, err.message);
        myoFeature = [];
        ClockWindowed = [];
    end