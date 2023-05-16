function [side, rotation, stim] = createCounterbalancedPseudorandomizedConditions(stimDir)
% Create a cells of pseudorandomized stimulus order for each subject
% A true color should not be presented twice in consecutive order
% Do I need catch trials without rivalry?


%% Factors
% the side where the true color is presented
sides = {'left', 'right'};
% direction in which the true color is rotated (inverted color is rotated
% in the other direction
rotation = {'clockwise', 'counter-clockwise'};
% all the stimuli used
stimuli = dir(fullfile(stimDir,'*.png'));
stimuliNames = {stimuli(:).name};

%% BalanceTrials
numTrials = length(sides)*length(stimuliNames);
randomize = true;

[side, rotation, stim] = BalanceTrials(numTrials,randomize,sides,rotation,stimuliNames);