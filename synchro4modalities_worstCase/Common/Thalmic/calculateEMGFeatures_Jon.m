function [myoFeature, ClockWindowed] = calculateEMGFeatures_Jon(subjMyo, featureNumber, subjTime)
    [Feature, ClockWindowed] = CalculateFeatures_JonFeatures(subjMyo.emgDataInterpol, ...
        subjMyo.emgTimeInterpol, featureNumber, subjMyo.windowSize, subjMyo.windowOverlap, subjMyo.normMethod);
%     myoFeature = spline(ClockWindowed', Feature', subjTime')';
    myoFeature = Feature;
    