function fileConverter(directory, sourceFileType, targetFileType)
    % converts files of one type into another
    
    if ~exist('directory', 'var')
        directory = 'C:\Documents\MATLABResults\script41_fullseg_varyingnormalization3\newfolder\';
        targetDir = 'C:\Documents\MATLABResults\script41_fullseg_varyingnormalization3\newfolder\';
        sourceFileType = 'fig';
        targetFileType = 'eps';
        targetFileTypeSpec = 'epsc';
    end
    
    if ~exist(targetDir)
        mkdir(targetDir); 
    end
    
    baseFolderDir = dir(directory);
    for i = 1:length(baseFolderDir)
        currFolderStruct = baseFolderDir(i);
        fullFilePath = [directory currFolderStruct.name];
        
        % check the currently 'active' folder
        if strcmp(currFolderStruct.name(1), '.')
            % if the dir result starts with a period...not wanted
            continue
        elseif currFolderStruct.isdir == 1
            continue
        elseif ~strcmp(currFolderStruct.name(end-2:end), sourceFileType)
            % not the type of file we're looking for
            continue
        end
        
        h = hgload(fullFilePath);
        
        % if the labels needs to be modified
%         xlim([6 20]);
% title('');
%         xlabel('Time [s]');
%         ylabel('End-effector position [m]');
        
% N = 24;
% set(gca,'fontsize',N)
% set(findall(gcf,'type','text'),'fontSize',N)
set(h, 'position', [1500 570 560 420*2/3]);
    
    
% output = ['5_' mvtNumber '_slow' setNumber '_ekf_' position '_' figTypeStr];
output = currFolderStruct.name(1:end-4);
        saveas(h, [targetDir output '.' targetFileType], targetFileTypeSpec);
        
% hmm things
% xlim([22 38])
% 
%         saveas(h, [targetDir currFolderStruct.name(1:end-4) '.' targetFileType], targetFileTypeSpec);



        close(h);
    end
end