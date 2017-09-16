function [Feature, Signal, ClockWindowed, OtherFeatures] = Calculate_Features(Data, RMS, WindowSize, WindowShift )
% This function recieves raw EMG signals and calculates the RMS from which the inner-product features are then computed.
% The RMS and inner-products are computed over overlapping/moving window
% the code also allows to compute the inner-product directly from the raw signals

% Input:
% Data: recorded  signals represented by cell array of size nx3
% col 1: indicate which row represent accelorometry data and which ones
% are EMG
% col 2: system clock
% RMS: compute RMS [1], default [1]
% WindowSize: The code computesthe features over a specified window;
% Default = 50.
% WindowShift: indicates the forward shift between subsequent windows;
% Default = 20.

% Output:
% Feature: inner-product features. Matrix of size mx28, where m is the number of
% samples we have after downsampling the signals through RMS or inner-product computation.
% m's value depends on the size of raw signal (number of its samples), window size and window shift.
% Ali-Akbar Samadani, Jan. 20th, 2015
% ===========================================================================

% Set the required parameters
% Check number of input argument
switch nargin
    case 0
        error('No argument/No EMG observation is passed')
    case 1
        %if no feature is selected, then, only the RMS of the EEG channels is computed.
        RMS = 1;
        WindowSize = 50; % default window size
        WindowShift = 20; % default window shift
        
    case 2
        WindowSize = 50; % default window size
        WindowShift = 20; % default window shift
        
    case 3
        WindowShift = 50;
end
% IndexWindow: contains indecies for start and end of the moving window;
% e.g. IndexWindow(1,i)  and IndexWindow(2,i) are the start and end of the
% i^th window, respectively.

Raw_EMG = Data.emgData;
Clock = Data.emgTime;

% Raw_EMG = cell2mat(Data(cell2mat(Data(:,1)) == 2,3));
% Clock = cell2mat(Data(cell2mat(Data(:,1)) == 2,2));

IndexWindow = [1:WindowShift:size(Raw_EMG,1);(1:WindowShift:size(Raw_EMG,1))+WindowSize];
IndexWindow(:,IndexWindow(2,:) > size(Raw_EMG,1)) = [];
% IndexWindow(:,end+1) = [IndexWindow(1,end)+WindowShift, size(Raw_EMG,1)];
% % add the last missing bits as incomplete windows

ClockWindowed = Clock(IndexWindow(2, :), :);

%compute RMS?
if RMS
    Signal = cell2mat(arrayfun(@(y) arrayfun(@(x) norm(Raw_EMG(IndexWindow(1,x):...
        IndexWindow(2,x),y))/sqrt(diff(IndexWindow(:,x))),...
        1:length(IndexWindow))',1:size(Raw_EMG,2),'uniformoutput',false));
    
    % compute inner-product feature
    Feature = cell2mat(arrayfun(@(y) cell2mat(arrayfun(@(z) arrayfun(@(x) Signal(x,y)*Signal(x,z),...
        1:length(Signal))',setdiff(y:8,y),...
        'uniformoutput', false)),1:size(Raw_EMG,2),'uniformoutput',false));
    
else
    Signal = Raw_EMG;
    % compute inner-product feature
    
    Feature = cell2mat(arrayfun(@(y) cell2mat(arrayfun(@(z) arrayfun(@(x) dot(Signal(IndexWindow(1,x):...
        IndexWindow(2,x),y),Signal(IndexWindow(1,x):...
        IndexWindow(2,x),z)), 1:length(IndexWindow))',setdiff(y:8,y),...
        'uniformoutput', false)),1:size(Raw_EMG,2),'uniformoutput',false));
end

% % % calculate some other features
% % % signal norm
% % normSignal = zeros(1, size(Signal, 1));
% % for ind_normizer = 1:size(Signal, 1)
% % normSignal(ind_normizer) = norm(Signal(ind_normizer, :));
% % end
% % signalNorm = normSignal';
% % 
% % % select the top two myoSignal channels at a
% % % given timestep and use the ratio of these two
% % % signals
% % signalRatio = zeros(1, size(Signal, 1));
% % for ind_timesteps = 1:size(Signal, 1)
% %     currDataRow = Signal(ind_timesteps, :);
% %     [maxVal, maxInd] = max(currDataRow);
% %     currDataRow(maxInd) = 0;
% %     [secondVal, secondInd] = max(currDataRow);
% %     
% %     signalRatio(ind_timesteps) = secondVal/maxVal;
% % end
% % 
% % % signal frequency
% % Fs = 1/mean(diff(ClockWindowed/1000)); % Sampling frequency
% % L = length(ClockWindowed);    % Length of signal
% % % t = ClockWindowed;            % Time vector
% % % Sum of a 50 Hz sinusoid and a 120 Hz sinusoid
% % % x = 0.7*sin(2*pi*50*t) + sin(2*pi*120*t); 
% % % y = x + 2*randn(size(t));     % Sinusoids plus noise
% % % plot(Fs*t(1:50),y(1:50))
% % % title('Signal Corrupted with Zero-Mean Random Noise')
% % % xlabel('time (milliseconds)')
% % 
% % for i = 1:size(IndexWindow, 2)
% %     y = Raw_EMG(IndexWindow(1, i):IndexWindow(2, i), :);
% %     % y = Raw_EMG;
% %     NFFT = 2^nextpow2(1); % Next power of 2 from length of y
% %     Y(i, :) = fft(y,NFFT)/1;
% %     f = Fs/2*linspace(0,1,NFFT/2+1);
% % end
% % 
% % % y = Signal;
% % % % y = Raw_EMG;
% % % NFFT = 2^nextpow2(L); % Next power of 2 from length of y
% % % Y = fft(y,NFFT)/L;
% % % f = Fs/2*linspace(0,1,NFFT/2+1);
% % 
% % % Plot single-sided amplitude spectrum.
% % figure;
% % plot(f,2*abs(Y(1:NFFT/2+1, :))) 
% % title('Single-Sided Amplitude Spectrum of y(t)')
% % xlabel('Frequency (Hz)')
% % ylabel('|Y(f)|')
% % 
% % OtherFeatures.innerProduct = innerProduct;
% % OtherFeatures.signalNorm = signalNorm;
% % OtherFeatures.signalRatio = signalRatio;
