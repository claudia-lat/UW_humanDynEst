function checkPathWriteToConsole(targetpath, fileset)
if ~isempty(targetpath) && ~exist(targetpath, 'file')
    fprintf('File missing: %s (%s)\n', targetpath, fileset.exercise);
end