function [Fs, IndexWindow, ClockWindowed, RawEMG] = thalmicNormalize(Clock, RawEMG, WindowSize, WindowShift, Norm)

Fs = floor(1/mean(diff(Clock)));
 
%% define moving windows, removing ones that exceed the limits
IndexWindow = [1:WindowShift:size(RawEMG,1);...
    (1:WindowShift:size(RawEMG,1))+WindowSize];
IndexWindow(:,IndexWindow(2,:) > size(RawEMG,1)) = []; 
% IndexWindow(:,end+1) = [IndexWindow(1,end)+WindowShift, size(RawEMG,1)];

if isempty(IndexWindow)
    % if the declared window size is too big, then just have one window
    IndexWindow = [1; size(RawEMG, 1)];
end

ClockWindowed = Clock(IndexWindow(2, :), :);

%%
%normalize the signal (channel-specific normalization)
switch Norm
    case 'None'
        
    case 'Median'
        RawEMG = RawEMG./repmat(median(abs(RawEMG)),length(RawEMG),1);
    case 'Mean'
        RawEMG = RawEMG./repmat(mean(abs(RawEMG)),length(RawEMG),1);
    case 'Max'
        RawEMG = RawEMG./repmat(max(abs(RawEMG)),length(RawEMG),1);
    case 'MaxMax'
%     %     Alternatively, normalize by max across channels
        RawEMG = RawEMG./max(max(abs(RawEMG)));

    otherwise
        RawEMG = RawEMG ./ Norm;
end