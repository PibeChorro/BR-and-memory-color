function [side,stim] = createCounterbalancedPseudorandomizedConditions(stimDir)
% Create a cells of pseudorandomized stimulus order for each subject
% A true color should not be presented twice in consecutive order
% Do I need catch trials without rivalry?


%% Factors
% the side where the true color is presented
sides = {'left', 'right'};
% all the stimuli used
stimuli = dir(fullfile(stimDir,'*.png'));
stimuliNames = {stimuli(:).name};

%% BalanceTrials
numTrials = length(sides)*length(stimuliNames);
randomize = true;

[side, stim] = BalanceTrials(numTrials,randomize,sides,stimuliNames);