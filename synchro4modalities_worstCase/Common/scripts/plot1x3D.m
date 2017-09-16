function h = plot1x3D(name, time, xdata, ydata, zdata, segInfo, cropInfo)
    % plot the data
    h = figure;

    scatter3(xdata, ydata, zdata, 'b.'); % all data
    hold on
    
    % now find the data highlighted by segInfo
    [~, closeInd_start] = findClosestValue(segInfo.timeStart, time);
    [~, closeInd_end] = findClosestValue(segInfo.timeEnd, time);
    
    for i = 1:length(closeInd_start)
        indPlot = closeInd_start(i):closeInd_end(i);
        scatter3(xdata(indPlot), ydata(indPlot), zdata(indPlot), 'go'); % all data
    end
    
    scatter3(xdata(closeInd_start), ydata(closeInd_start), zdata(closeInd_start), 'ro'); % all data
    scatter3(xdata(closeInd_end), ydata(closeInd_end), zdata(closeInd_end), 'ro'); % all data
    
    title(name);
end