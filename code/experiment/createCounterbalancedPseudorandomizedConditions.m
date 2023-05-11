function [side,stim] = createCounterbalancedPseudorandomizedConditions(stimDir, sub)
% Create a cells of pseudorandomized stimulus order for each subject
% A true color should not be presented twice in consecutive order
% Do I need catch trials without rivalry?

%% Factors
% read in the 
% the side where the true color is presented
sides = {'left', 'right'};
colors = {'green', 'orange', 'red', 'yellow'};
% all the stimuli used
trueColorStimDir = os.path.join(stimDir, 'true_color');
stimuli = dir(fullfile(trueColorStimDir,'*.png'));
stimuliNames = {stimuli(:).name};

%% simplest version 
% every subject sees every stimulus in complete random order
numTrials = length(sides)*length(stimuliNames);
randomize = true;

while true
    [side, stim] = BalanceTrials(numTrials,randomize,sides,colorStim);
    if all(~strcmp(stim(1:end-1), stim(2:end)))
        % If no value appears in consecutive order, break out of the loop
        break;
    end
end

%% simple block version
% every subject sees every stimulus in blocks
% each block is counterbalanced that it shows the same number of objects
% per color

%% color run version
% every subject sees every stimulus but one true color is shown in a run.
% Order of stimuli within runs is random
% Order of colors over subjects is pseudorandomize

stimuliMatrix = repmat({''},20,length(colors));
% go through colors and get stimuli belonging to color category
for c = 1:length(colors)
    % all stimuli of the current color
    colorStimIdx = contains(stimuliNames, colors(c));
    colorStim = stimuliNames(colorStimIdx);
    numTrials = length(sides)*length(colorStim);
    while true
        [side, stim] = BalanceTrials(numTrials,randomize,sides,colorStim);
        if all(~strcmp(stim(1:end-1), stim(2:end)))
            % If no value appears in consecutive order, break out of the loop
            break;
        end
    end
    stimuliMatrix(:,c) = stim;
end


%% selective color run version
% every subject sees only a subset of stimuli, i.e., only two out of the
% four colors.
% Order of stimuli within runs is random
% Order of color subsets is pseudorandomized in a way that each color was
% seen just as often as every other color

%% multiple color run version 
% every subject sees all stimuli but in each run you have combinations of
% two colors that are random

end