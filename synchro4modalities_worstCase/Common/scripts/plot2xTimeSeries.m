function h = plot2xTimeSeries(name, timeTop, dataTop, timeBot, dataBot, segInfo, cropInfo)
    % plot the data
    h = figure;
    
    % zero offset the whole thing
    initTime = 0;
    
    if isempty(segInfo)
        algValStart = [];
        algValEnd = [];
    else
        algValStart = segInfo.timeStart - initTime;
        algValEnd = segInfo.timeEnd - initTime;
    end
    
    if isempty(cropInfo)
        cropValStart = [];
        cropValEnd = [];
    else
        cropValStart = cropInfo.timeStart - initTime;
        cropValEnd = cropInfo.timeEnd - initTime;
    end

    if ~isempty(timeBot)
        h1 = subplot(2, 1, 1);
    end
    
    plot(timeTop, dataTop);
    title(name);
    
    if ~isempty(algValStart)
        plotBoxes(h, algValStart(segInfo.use == 1), algValEnd(segInfo.use == 1), 'g');
        plotBoxes(h, algValStart(segInfo.use == 0), algValEnd(segInfo.use == 0), 'r');
    end
    
    if ~isempty(cropValStart)
        plotBoxes(h, cropValStart, cropValEnd, 'k');
    end
    
%     ylim([-20 20]);

    if ~isempty(timeBot)
        h2 = subplot(2, 1, 2);
        plot(timeBot, dataBot);
        if ~isempty(algValStart)
            plotBoxes(h, algValStart(segInfo.use == 1), algValEnd(segInfo.use == 1), 'g');
            plotBoxes(h, algValStart(segInfo.use == 0), algValEnd(segInfo.use == 0), 'r');
        end

        if ~isempty(cropValStart)
            plotBoxes(h, cropValStart, cropValEnd, 'k');
        end
    end
        title(name);
    
%     ylim([-3*pi/2 3*pi/2]);

    linkaxes([h1, h2], 'x');
end