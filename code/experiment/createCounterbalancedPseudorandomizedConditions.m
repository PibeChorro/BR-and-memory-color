function createCounterbalancedPseudorandomizedConditions(log)
% Create a cells of pseudorandomized stimulus order for each subject
% A true color should not be presented twice in consecutive order
% Do I need catch trials without rivalry?

%% Factors
% read in the 
% the side where the true color is presented
sides = {'left', 'right'};
% direction in which the true color is rotated (inverted color is rotated
% in the other direction
% rotations = {'clockwise', 'counter-clockwise'};
% colors used
colors = {'blue', 'green', 'yellow', 'orange', 'red'};      
% all the stimuli used
trueColorStimDir = fullfile(log.subjectDirectory, 'stimuli', 'true_color');
stimuli = dir(fullfile(trueColorStimDir,'*.png'));
stimuliNames = {stimuli(:).name};

%% controlled block version
% Every subject sees every stimulus in blocks
% One block shows one stimulus of each color in an ordered fashon. 
% The colors are {'blue', 'green', 'yellow', 'orange', 'red'} and we want
% to show them skipping one color in order to have a larger distance
% between the colors of the stimuli (e.g., blue, yellow, red, green,
% orange)

numTrials       = length(stimuliNames)*length(sides);
trialsPerRun    = length(colors);
numRuns         = numTrials/trialsPerRun;

% assign sides for the true color stimuli
allSides = repmat(sides',length(stimuliNames),1);
% shuffle stimuli
[shuffledStimuliNames,indices] = Shuffle(stimuliNames);

% matrix to store trials in
subConditions.stimulus  = repmat({''},trialsPerRun,numRuns);
subConditions.side      = repmat({''},trialsPerRun,numRuns);

% fill matrix
for run = 1:numRuns
    % select a random starting index of the color
    idx = randi([1,trialsPerRun]);
    runConditions.stimuli = {};
    runConditions.sides = {};
    for trial = 1:trialsPerRun
        if isempty(shuffledStimuliNames)
            [shuffledStimuliNames,indices] = Shuffle(stimuliNames);
            indices = indices+length(stimuliNames);
        end
        colorStimIdx = find(contains(shuffledStimuliNames, colors(idx)),1);
        % fill matrices
        subConditions.stimulus{trial,run} = shuffledStimuliNames(colorStimIdx);
        subConditions.side{trial,run} = allSides{indices(colorStimIdx)};
        % fill cell arrays for talbe
        runConditions.stimuli{end+1} = shuffledStimuliNames(colorStimIdx);
        runConditions.sides{end+1} = allSides{indices(colorStimIdx)};
        % remove selected stimulus from list
        shuffledStimuliNames(colorStimIdx) = [];
        indices(colorStimIdx) = [];
        % generate new color index
        idx = mod(idx+1,5) + 1;
    end
    % reverse the order of the color cell array
    colors = flip(colors);
    % write run struct into table and save for subject
    runConditions.stimuli = runConditions.stimuli';
    runConditions.sides = runConditions.sides';
    runTable = struct2table(runConditions);
    writetable(runTable, fullfile(log.subjectDirectory,[log.sub sprintf('_run-%02d',run) '.csv']));
%     writetable(runTable,['test_' num2str(run) '.csv']);
end
save(fullfile(log.subjectDirectory, 'subConditions'),'subConditions');
end