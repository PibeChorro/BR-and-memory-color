%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main script for a binocular rivalry (BR) experiment using images of
% objects in either their "correct" - i.e., associated - color or in an
% "incorrect" color - i.e., a color normally not associated with the
% object.
% Written by Vincent Plikat 13/04/2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Variables
% Constant variables
numRuns = 0;
numTrials = 0;
numBreaks = 0;

distToMonitor = 0;
monitorWidth = 0;
monitorHeight = 0;

keys = [];

stimDirectory = fullfile('..', '..', 'stimuli');
stimuliNames = {};

dataDir = fullfile('..', '..', 'rawdata');

useET = false;

% Dynamic variables
task = '';              % there probably will be more than one condition

subjectData = table; % or maybe a cell array?

try
    % Varialbes read out by the system and specific to the hardware
    ptb = PTBSettings();
    %% Read in stimuli
    try
    catch READING_ERROR
        rethrow(READING_ERROR);
    end
    
    %% Subject input
    [sub, subjectDir, language] = inputSubID(dataDir);
    fprintf (sub);
    fprintf ('\n');
    fprintf (subjectDir);
    fprintf ('\n');
    
    %% Get design settings
    design = designSettings(language);
    
    %% Inclusion of eye tracker
    if useET
        ET = IncludeEyetracker(sub);
        %% Calibration and Validation
        EyelinkDoTrackerSetup(ET);
        EyelinkDoDriftCorrection(ET);
        
        % start recording eye position
        Eyelink('StartRecording');
        % record a few samples before we actually start displaying
        WaitSecs(0.1);
        % mark zero-plot time in data file
        Eyelink('Message', 'SYNCTIME');
        % sets EyeUsed to -1 because we do not know which eye we use. This is
        % asked before we sample
        EyeUsed = -1;
    end
    
    %% Actual experiment
    % Welcome screen
    DrawFormattedText (ptb.window, design.Introduction, 'center', 'center',ptb.FontColor);
    Screen ('Flip', ptb.window);
    WaitSecs (0.5);
    KbWait();
    
    % Instructions
    DrawFormattedText (ptb.window, design.Instruction1, 'center', 'center',ptb.FontColor);
    Screen ('Flip', ptb.window);
    WaitSecs (0.5);
    KbWait();
    
    
    % Loop over trials
    for trial = 1%:numTrials
        imageDir = fullfile(stimDirectory, 'stimuli', '1.png');
        strawberry = imread(imageDir);
        imageTexture = Screen('MakeTexture', ptb.window, strawberry);
        % Get an initial screen flip for timing
        vbl = Screen('Flip', ptb.window);
        % Draw the image to the screen, unless otherwise specified PTB will draw
        % the texture full size in the center of the screen. We first draw the
        % image in its correct orientation.
        Screen('DrawTexture', ptb.window, imageTexture, [], [], 0);
        
        % Flip to the screen
        vbl  = Screen('Flip', ptb.window, vbl + (3 - 0.5) * ptb.ifi);
    end

    sca
    
    %% End of experiment
    % save data
    % catch error
catch MY_ERROR
    rethrow(MY_ERROR);
end