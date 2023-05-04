function log = createSubDir(log)

log.sub = strcat('sub-', sprintf('%02s', log.subjectNr));
log.subjectDirectory = fullfile(log.dataDir, log.sub);
% check if subject already exists
if (isfolder(log.subjectDirectory) && ~(strcmp(log.subjectNr, 'test')))
    tripleCheck = input('Subject folder already exists. Do you want to change subject ID Y/N [Y]?\n', 's');
    if (strcmp(tripleCheck, 'y') || isempty(tripleCheck))
        log = inputSubID(log);
    end
else
    % create subject folder
    mkdir(log.subjectDirectory);
end
end