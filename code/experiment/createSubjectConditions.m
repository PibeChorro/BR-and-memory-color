function conditionTable = createSubjectConditions()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

colors = {'green', 'orange', 'red', 'yellow'};
%% color run version
% every subject sees every stimulus but one true color is shown in a run.
% Order of colors over subjects is pseudorandomize
possibleColorCombinations = factorial(length(colors));
allColorCombinations = repmat(colors',1,possibleColorCombinations);
allColorCombinations = Shuffle(allColorCombinations);

conditionTable = cell2table(allColorCombinations);

% Generate new column names
newNames = arrayfun(@(x) sprintf('sub-%02d', x), 1:width(conditionTable), 'UniformOutput', false);

% Update the table with the new column names
conditionTable.Properties.VariableNames = newNames;

% add a column with the runs in the beginning
runs = 1:length(colors);
runs = runs';
conditionTable = addvars(conditionTable, runs, 'Before','sub-01');

writetable(conditionTable, 'conditions.csv');

%% selective color run version
% every subject sees only a subset of stimuli, i.e., only two out of the
% four colors.
% Order of color subsets is pseudorandomized in a way that each color was
% seen just as often as every other color

%% multiple color run version 
% every subject sees all stimuli but in each run you have combinations of
% two colors that are random
end