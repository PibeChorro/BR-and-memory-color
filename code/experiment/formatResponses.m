function [sortedResultsTable, success] = formatResponses(log,ptb)
% get the response data from log and extract all the important information
% for further analyses (see data table example in main)

% OUTPUT
% success: boolean variable stating whether or not the exportation into the
% data format was successfull

try
    % get rid of keys that are not response keys for the task
    log.data.idDown(find(~ismember(log.data.idDown,[ptb.Keys.left ptb.Keys.right])))    = [];
    log.data.timeDown(find(~ismember(log.data.idDown,[ptb.Keys.left ptb.Keys.right])))  = [];
    log.data.idUp(find(~ismember(log.data.idUp,[ptb.Keys.left ptb.Keys.right])))        = [];
    log.data.timeUp(find(~ismember(log.data.idUp,[ptb.Keys.left ptb.Keys.right])))      = [];

        
    % stuff to save onset, duration and percept in
    percepts = {};
    stimulus = {};
    durations = [];
    onsets = [];

    % for each trial
    for trl = 1:length(log.data.stimOnset)
        %% get key presses during trial
        trialKeyTimeDown    = intersect(find(log.data.timeDown >= log.data.stimOnset(trl)), ...
            find(log.data.timeDown < log.data.stimOffset(trl)));
        trialKeyTimeUp      = intersect(find(log.data.timeUp >= log.data.stimOnset(trl)), ...
            find(log.data.timeUp < log.data.stimOffset(trl)));

        % get the actual time and id key presses and releases
        trialTimeDown   = log.data.timeDown(trialKeyTimeDown);
        trialTimeUp     = log.data.timeUp(trialKeyTimeUp);
        trialIdDown     = log.data.idDown(trialKeyTimeDown);
        trialIdUp       = log.data.idUp(trialKeyTimeUp);

        % check whether the first key release is prior to the first key
        % press
        if trialTimeUp(1)<trialTimeDown(1)
            trialTimeUp(1) = [];
        end

        % Remove the last  percept, since we cannot know how long it would 
        % have lasted
        % If the number of key presses is larger than the key releases, we
        % discard the last key press. Else the last percept was a mixed
        % percept which we discard at the end during analyses
        if length(trialTimeDown)>length(trialTimeUp)
            trialTimeDown(end)  = [];
            trialIdDown(end)    = [];
        elseif length(trialTimeDown)<length(trialTimeUp)
            error('You have more key releases than key presses')
        end

        %% separate into true color and false color key presses
        % true color
        trueColorDown   = trialTimeDown(trialIdDown==ptb.Keys.left);
        trueColorUp     = trialTimeUp(trialIdUp==ptb.Keys.left);
        
        % false colorper
        falseColorDown  = trialTimeDown(trialIdDown==ptb.Keys.right);
        falseColorUp    = trialTimeUp(trialIdUp==ptb.Keys.right);

        if ~isempty(trueColorDown) && ~isempty(trueColorUp) % if there is at least one percept in this trial
            trueColorPressed = trueColorUp - log.data.stimOnset(1);
            trueColorDurations = trueColorUp - trueColorDown;
        else
            warning('The true color was not perceived in trial %u \n', trl);
        end
        durations = [durations; trueColorDurations];
        onsets = [onsets; trueColorPressed];
        percepts = [percepts; repmat({'true_color'},length(trueColorDurations),1)];
        if ~isempty(falseColorUp) && ~isempty(falseColorDown) % if there is at least one percept in this trial
            falseColorPressed = falseColorUp-log.data.stimOnset(1);
            falseColorDurations = falseColorUp - falseColorDown;
        else
            warning('The false color was not perceived in trial %u \n', trl);
        end
        durations = [durations; falseColorDurations];
        onsets = [onsets; falseColorPressed];
        percepts = [percepts; repmat({'false_color'},length(falseColorDurations),1)];
        % add mixed percepts when nothing was pressed
        if ~isempty(trialIdDown(2:end)) && ~isempty(trialIdUp(1:end-1))
            %
            mixedPressed = trialTimeUp(2:end)-log.data.stimOnset(1);
            mixedDurations = trialTimeDown(2:end)-trialTimeUp(1:end-1);
        end
        durations = [durations; mixedDurations];
        onsets = [onsets; mixedPressed];
        percepts = [percepts; repmat({'mixed'},length(mixedDurations),1)];
    
        numSwitches = length(trueColorDurations) + length(falseColorDurations) + length(mixedDurations);
        stimulus = [stimulus; repmat({log.data.stimuli(trl)},numSwitches,1)];
    end
    success = true;
    resultsTable = table(stimulus, percepts, onsets, durations);
    sortedResultsTable = sortrows(resultsTable, 3);


catch READINGERROR
    fprintf('Something went wrong in trial %u\n', trl);
    success = false;
    sortedResultsTable = [];
end