function [sub, subjectDirectory] = createSubDir(dataDir, subjectNr)

sub = strcat('sub-', sprintf('%02s', subjectNr));
subjectDirectory = fullfile(dataDir, sub);
% check if subject already exists
if (isfolder(subjectDirectory) && ~(strcmp(subjectNr, 'test')))
    tripleCheck = input('Subject folder already exists. Do you want to change subject ID Y/N [Y]?\n', 's');
    if (strcmp(tripleCheck, 'y') || isempty(tripleCheck))
        [sub, subjectDirectory] = inputSubID(dataDir);
    end
elseif strcmp(subjectNr, 'test')
    fprintf('TESTRUN');
else
    % create subject folder
    mkdir(subjectDirectory);
end
end