function [Feature, ClockWindowed] = CalculateFeatures_PerWindow(RawEMG, Clock, selectedFeature, WindowSize, WindowShift, Norm)  

% % Ali-Akbar Samadani, March 15th, 2015
% Data: input data, a gesture representation in terms of of 8 EMG channels 
% Data is of size T x 8. 
% Fs: sampling frequecy
% WindowSize: for windowing purpose, default = 256
% WindowShift: round(WindowSize/10)
% selectedFeature: which feature do you want to compute from raw EMG
% signals
% Norm: what type of normalization to apply on Data. options are: median,
% mean, max

% Note: in each call for this function a single feature should be selected:
% The selected feature is indicated by "selectedFeature" input as an integer, 0< selectedFeature < 14 

[Fs, IndexWindow, ClockWindowed, RawEMG] = thalmicNormalize(Clock, RawEMG, WindowSize, WindowShift, Norm);

%% compute RMS curves (no need for this when features are computed for each moving window separately!)
% RMS =  cell2mat(arrayfun(@(x) arrayfun(@(y) norm(RawEMG(IndexWindow(1,x):...
%     IndexWindow(2,x),y))/sqrt(diff(IndexWindow(:,x))),1:size(RawEMG,2)),...
%     1:size(IndexWindow, 2),'uniformoutput',false)');

% the signal calculation from Ali's old code. reports the same results tho
% Signal = cell2mat(arrayfun(@(y) arrayfun(@(x) norm(Data(IndexWindow(1,x):...
%     IndexWindow(2,x),y))/sqrt(diff(IndexWindow(:,x))),...
%     1:size(IndexWindow, 2))',1:size(Data,2),'uniformoutput',false));
%%
switch selectedFeature
    case 1 % Mean Absolute Value
        Feature = cell2mat(arrayfun(@(x) sum(abs(RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),:)))/diff(IndexWindow(:,x)),...
            1:size(IndexWindow, 2),'un',0)');

        %%
    case 2 % InnerProduct over moving windows (normalized by the length of the gesture)
        Feature = cell2mat(arrayfun(@(x) cell2mat(arrayfun(@(y) arrayfun(@(z) ...
                  dot(RawEMG(IndexWindow(1,x):IndexWindow(2,x),y), ...
                  RawEMG(IndexWindow(1,x):IndexWindow(2,x),z)), setdiff(y:8,y)),...
                  1:size(RawEMG,2), 'un',0)),1:size(IndexWindow, 2), 'un',0)');

        %%
    case 3 % Variance 
        Feature = cell2mat(arrayfun(@(x) var(RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),:)),...
            1:size(IndexWindow, 2),'un',0)');
        
        %%
    case 4 % Waveform-Length
        Feature = cell2mat(arrayfun(@(x) sum(abs(diff(RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),:))))/diff(IndexWindow(:,x)),...
            1:size(IndexWindow, 2),'un',0)');
        
        %%
    case 5 % Slope sign changes (this feature should be computed for a smoothed signal e.g., RMS)
        Slope = arrayfun(@(x) diff(RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),:)), 1:size(IndexWindow, 2),'un',0);
        Feature = cell2mat(cellfun(@(x) sum((x(2:end,:).*x(1:end-1,:))<0)/size(x,1),...
                            Slope, 'un',0)');

        %%
    case 6% Hurst Exponent = Log(Range/StD)/Log(n), where n is number of samples
        Feature = cell2mat(arrayfun(@(x) log(range(RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),:))./std(RawEMG(IndexWindow(1,x):IndexWindow(2,x),:)))...
            /log(diff(IndexWindow(:,x))), 1:size(IndexWindow, 2),'un',0)');
     
      
        %%
    case 7 % Hjorth Parameters (Activity, Mobility, and Complexity)
        % ideally, computed for filtered signals
        % Carmen Vidaurre et al. 2009 propose computing Hjorth paramters
        % for different order of derivatives of the signals
        % Format: stucture with 3 feilds 1) Activity, 2) Mobility, and 3)
        % Complexity.
   
        Mobility  = arrayfun(@(x) sqrt(var(diff(RawEMG(IndexWindow(1,x):IndexWindow(2,x),:)))./...
                        var(RawEMG(IndexWindow(1,x):IndexWindow(2,x),:))),1:size(IndexWindow, 2),'un',0);
        
        Complexity = cell2mat(arrayfun(@(x) sqrt(var(diff(RawEMG(IndexWindow(1,x):IndexWindow(2,x),:),2))./...
                        var(diff(RawEMG(IndexWindow(1,x):IndexWindow(2,x),:))))./Mobility{x},...
                        1:size(IndexWindow, 2),'un',0)');
                    
        Mobility = cell2mat(Mobility');
        % compute Hjorth components for the first derivative of the
        % gesture
        
        dRMS = arrayfun(@(x) diff(RawEMG(IndexWindow(1,x):...
                IndexWindow(2,x),:)), 1:size(IndexWindow, 2),'un',0);
            
      % these features, dMobility and dComplexity are Hjorth parameters for
      % the first derivative of EMG signals over moving windows. 
      % in this reference (Carmen Vidaurre et al. 2009), they have shown
      % that Hjorth paramters for derivative signals are more informative
        dMobility  = arrayfun(@(x) sqrt(var(diff(dRMS{x}))./...
                        var(dRMS{x})),1:length(dRMS),'un',0);
        
        dComplexity = cell2mat(arrayfun(@(x) sqrt(var(diff(dRMS{x},2))./...
                        var(diff(dRMS{x})))./dMobility{x},...
                        1:length(dRMS),'un',0)');
                    
        dMobility = cell2mat(dMobility');
      
        Feature = [Mobility Complexity dMobility dComplexity]; % 10*log10(mean(cat(3,P{:}),3))
        
     
        %%
    case 8 % Descriptive statistics (Mean)
        Feature = cell2mat(arrayfun(@(x) mean(RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),:)),...
            1:size(IndexWindow, 2),'un',0)');

        %%
    case 9 % Descriptive statistics (Skewness)
        
       Feature = cell2mat(arrayfun(@(x) skewness(RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),:)),...
            1:size(IndexWindow, 2),'un',0)');
  
        %%
    case 10 % Descriptive statistics (Kurtosis)
        
        Feature = cell2mat(arrayfun(@(x) kurtosis(RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),:)),...
            1:size(IndexWindow, 2),'un',0)');

        %%
    case 11 % Teager Energy Operator
        
        RawEMG_windowed = arrayfun(@(x) RawEMG(IndexWindow(1,x):IndexWindow(2,x),:),...
            1:size(IndexWindow, 2),'un',0);
        
        NE = cellfun(@(x) x(2:end-1,:).^2 - x(1:end-2,:).*x(3:end,:),...
            RawEMG_windowed,'un',0);
        
      
        Feature = cell2mat(cellfun(@(x) mean(x),NE,'un',0)');
        
%%       
    case 12 % Entropy
        Qlevel = 32; % you can decide what level of quanitzation to consider for producing histograms
        RawEMG_windowed = arrayfun(@(x) RawEMG(IndexWindow(1,x):IndexWindow(2,x),:),...
            1:size(IndexWindow, 2),'un',0);
        xRMS = cellfun(@(y) cell2mat(arrayfun(@(x) quantentr(y(:,x),Qlevel),...
            1:size(y,2),'un',0)), RawEMG_windowed,'un',0);
        
        % %         estimate pdf
        pdfest = cellfun(@(y) arrayfun(@(x) accumarray(y(:,x)+1,1)/length(y),...
                    1:size(y,2),'un',0),xRMS,'un',0);
        pdfest =  cellfun(@(x) arrayfun(@(y) x{y}/sum(x{y}), 1:length(x), 'un',0), pdfest,'un',0);
        
        
        Entropy = cell2mat(cellfun(@(x) arrayfun(@(y) -sum(x{y}(x{y}>0).*log(x{y}(x{y}>0))),...
                    1:length(x)),pdfest,'un',0)'); % Entropy
                
        pdfest =  cellfun(@(x) arrayfun(@(y) x{y} + eps, 1:length(x),'un',0),pdfest,'un',0);
        RelEntropy = cell2mat(cellfun(@(z) cell2mat(arrayfun(@(x) ...
            arrayfun(@(y) ...
            sum(z{x}.*log(z{x}./...
            z{y})),setdiff(x:8,x)),...
            1:length(z),'un',0)),pdfest, 'un',0)');
        
        
        jointProb = cellfun(@(z) arrayfun(@(x) arrayfun(@(y) ...
            accumarray([z(:,x) z(:,y)]+1, 1)/length(z), setdiff(x:8,x), 'un',0),...
            1:size(z,2),'un',0),xRMS,'un',0);
        jointProb = cellfun(@(z) arrayfun(@(x) cell2mat(arrayfun(@(y) z{x}{y}(:),1:length(z{x}),'un',0)),...
            1:length(z),'un',0),jointProb,'un',0);
        
        jointEntropy = cellfun(@(z) cell2mat(arrayfun(@(x) arrayfun(@(y) -sum(z{x}(z{x}(:,y)>0,y).*log(z{x}(z{x}(:,y)>0,y))),...
            1:size(z{x},2)),1:length(z),'un',0)),jointProb,'un',0);
        
        SumPairEntropy = arrayfun(@(z) cell2mat(arrayfun(@(x) arrayfun(@(y) sum([Entropy(z,x) Entropy(z,y)]),setdiff(x:8,x)), ...
            1:size(Entropy,2),'un',0)),1:size(Entropy,1),'un',0);
                
        MI = cell2mat(cellfun(@(x,y) arrayfun(@(z) x(z) - y(z),1:length(x)), SumPairEntropy, jointEntropy,'un',0)');
        
        
        
        
        Feature = [Entropy RelEntropy cell2mat(jointEntropy') MI];
        %%   
    case 13 % Angle between the two channels (not a feature for entire signal, should be computed over short windows)
        RawEMG_windowed = arrayfun(@(x) RawEMG(IndexWindow(1,x):IndexWindow(2,x),:),...
            1:size(IndexWindow, 2),'un',0);
        
        Feature = cell2mat(cellfun(@(z) cell2mat(arrayfun(@(x) arrayfun(@(y) ...
            180/pi*acos(dot(z(:,x),z(:,y))/(norm(z(:,x))*norm(z(:,y)))), ...
            setdiff(x:8,x)),1:size(z,2),'un',0)),RawEMG_windowed,'un',0)') ;

   %%
   
    case 14 % frequency features
        
        %% Frequency domain feature computed for the raw data  and not RMS curves
        %peak and centroid frequencies and bandwidth
        zeroPad =100;
        
        % apply hamming window and compute fft over moving windows
        Data = arrayfun(@(x) [zeros(zeroPad,size(RawEMG,2)); ...
            repmat(hamming(diff(IndexWindow(:,x))+1),1,size(RawEMG,2)).*zscore(RawEMG(IndexWindow(1,x):IndexWindow(2,x),:)); ...
            zeros(zeroPad,size(RawEMG,2))], 1:size(IndexWindow, 2),'un',0);
        
        psd = cellfun(@(x) (fft(x))/size(x,1),Data,'un',0); % normalize to length of window
        psd(cellfun(@isempty, psd)) = []; psd(end) = [];
        % power spectral density
        PSD = mean(abs(cat(3,psd{:})).^2,3);
        PSD = PSD(1:floor(size(PSD)/2)+1,:);
        F =  round(Fs/2)*linspace(0,1,length(PSD));
        PSD = 10*log10(PSD); % log scale
        PSD = PSD - repmat(min(PSD),length(PSD),1) + eps;
        
        [~, maxFreq_inx] = max(PSD);
        PeakFreq = F(maxFreq_inx);
        
        centriodFreq = sum(repmat(F',1,size(PSD,2)).*PSD)./sum(PSD);
        bandWidth = arrayfun(@(x) sum((F'-centriodFreq(x)).^2.*PSD(:,x))./sum(PSD(:,x)),...
            1:length(centriodFreq));
        RelativePowPeakFrequency = PSD(maxFreq_inx) ./ sum(PSD);
        
        %% the following computes the width of the max peak of the channels
        Index = arrayfun(@(y) find(PSD(:,y) < .25*max(PSD(:,y))),1:size(PSD,2),'un', 0);
        
        [~ ,InxMax]=  max(PSD);
        [SortIndx] = arrayfun(@(y) find((Index{y} - InxMax(y))>0),1:length(Index),'un', 0);
        %fix for the cases where the peak is at the end of the interval and
        %and the right tail of it doesnt cross zero is cut. in such cases,  the right
        %tail zero crossing is set to the length of the swallow.
        for i = 1:length(SortIndx)
            if isempty(SortIndx{i})
                Index{i}(end+1) = length(PSD);
                if InxMax(i) == length(PSD);
                    SortIndx{i} = length(Index{i});
                else
                    SortIndx{i} = find((Index{i} - InxMax(i))>0);
                end
            end
            
            if SortIndx{i}(1)  == 1
                Index{i} =[1 ;Index{i}];
                SortIndx{i}(1) = 2;
            end
        end
        
        WidthPeak =  arrayfun(@(y) diff(Index{y}(SortIndx{y}(1)-1:SortIndx{y}(1))),1:length(Index));
        
        Feature = [PeakFreq  centriodFreq  ...
            bandWidth  RelativePowPeakFrequency ...
            WidthPeak ];

    case 15
        % RMS (from Ali's old code)
        RMS =  cell2mat(arrayfun(@(x) arrayfun(@(y) norm(RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),y))/sqrt(diff(IndexWindow(:,x))),1:size(RawEMG,2)),...
            1:size(IndexWindow, 2),'uniformoutput',false)');
        
% Signal = cell2mat(arrayfun(@(y) arrayfun(@(x) norm(Data(IndexWindow(1,x):...
%     IndexWindow(2,x),y))/sqrt(diff(IndexWindow(:,x))),...
%     1:size(IndexWindow, 2))',1:size(Data,2),'uniformoutput',false));

        Feature = RMS;
        
    case 16
        % RMS pairwise inner product (from Ali's old code)
        RMS =  cell2mat(arrayfun(@(x) arrayfun(@(y) norm(RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),y))/sqrt(diff(IndexWindow(:,x))),1:size(RawEMG,2)),...
            1:size(IndexWindow, 2),'uniformoutput',false)');
        
        Feature = cell2mat(arrayfun(@(y) cell2mat(arrayfun(@(z) arrayfun(@(x) RMS(x,y)*RMS(x,z),...
            1:size(RMS, 1))',setdiff(y:8,y),...
            'uniformoutput', false)),1:size(RawEMG,2),'uniformoutput',false));
        
    case 17
        % raw pairwise inner product (from Ali's old code)
        Feature = cell2mat(arrayfun(@(y) cell2mat(arrayfun(@(z) arrayfun(@(x) dot(RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),y),RawEMG(IndexWindow(1,x):...
            IndexWindow(2,x),z)), 1:size(IndexWindow, 2))',setdiff(y:8,y),...
            'uniformoutput', false)),1:size(RawEMG,2),'uniformoutput',false));
end


