function success = formatResponses(log)
% get the response data from log and extract all the important information
% for further analyses (see data table example in main)

% OUTPUT
% success: boolean variable stating whether or not the exportation into the
% data format was successfull

try
    % get rid of keys that are not response keys for the task

    % sort keys chronologically

    % for each trial
    for trl = 1:length(log.stimOnset)
        % find key events within this trial
        if~isempty(trialKeyTimeDown) % if there is at least one percept in this trial
        else
            warning('No percepts in trial %u \n', trl);
        end
    end
    success = true;
catch
    success = false;
end
end