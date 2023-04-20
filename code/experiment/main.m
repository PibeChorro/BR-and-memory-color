%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main script for a binocular rivalry (BR) experiment using images of
% objects in either their "correct" - i.e., associated - color or in an
% "incorrect" color - i.e., a color normally not associated with the
% object.
% Written by Vincent Plikat 13/04/2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Variables
% Constant variables

% design related
numRuns = 0;
numTrials = 0;
numBreaks = 0;

% hardware related
distToMonitor = 0;
monitorWidth = 0;
monitorHeight = 0;

keys = [];
useET = false;

% stimuli related
stimDirectory = fullfile('..', '..', 'stimuli');
trueColorDirectory = fullfile(stimDirectory, 'true_color');
invertedColorDirectory = fullfile(stimDirectory, 'inverted');
stimuliNames = {
    'green_frog_1';...
    'red_tomato'; ...
    'yellow_banana';
    };
imageFileEnding = '.png';

% data related
dataDir = fullfile('..', '..', 'rawdata');

% Dynamic variables
% design related
task = '';              % there probably will be more than one condition

% data related
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
    % fuse images to the eyes
    % Do this before anything else
    [xOffset, yOffset] = alignFusion(ptb);

    % Welcome screen
    % Select   left-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, 0);
    DrawFormattedText (ptb.window, design.Introduction, 'center', 'center',ptb.FontColor);
    % Select right-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, 1);
    DrawFormattedText (ptb.window, design.Introduction, 'center', 'center',ptb.FontColor);
    % Tell PTB drawing is finished for this frame:
    Screen('DrawingFinished', ptb.window);
    Screen ('Flip', ptb.window);
    WaitSecs (0.5);
    KbWait();
    
    % Instructions
    % Select   left-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, 0);
    DrawFormattedText (ptb.window, design.Instruction1, 'center', 'center',ptb.FontColor);
    % Select right-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, 1);
    DrawFormattedText (ptb.window, design.Instruction1, 'center', 'center',ptb.FontColor);
    % Tell PTB drawing is finished for this frame:
    Screen('DrawingFinished', ptb.window);
    Screen ('Flip', ptb.window);
    WaitSecs (0.5);
    KbWait();

    
    % Loop over trials
    for stim = 1:length(stimuliNames)
        trueColorStim = fullfile(trueColorDirectory, [stimuliNames{stim} imageFileEnding]);
        invertedColorStim = fullfile(invertedColorDirectory, [stimuliNames{stim} imageFileEnding]);
        img1 = imread(trueColorStim);
        img2 = imread(invertedColorStim);
        % Get an initial screen flip for timing
        vbl = Screen('Flip', ptb.window);
        % Draw the image to the screen, unless otherwise specified PTB will draw
        % the texture full size in the center of the screen. We first draw the
        % image in its correct orientation.
        
        % Select   left-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, 0);
        imageTexture1 = Screen('MakeTexture', ptb.window, img1);
        Screen('DrawTexture', ptb.window, imageTexture1, [], [], 0);
        % Select right-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, 1);
        imageTexture2 = Screen('MakeTexture', ptb.window, img2);
        Screen('DrawTexture', ptb.window, imageTexture2, [], [], 0);
        % Tell PTB drawing is finished for this frame:
        Screen('DrawingFinished', ptb.window);

        % Flip to the screen
        vbl  = Screen('Flip', ptb.window, vbl + (3 - 0.5) * ptb.ifi);
        WaitSecs(5);
    end

    sca
    
    %% End of experiment
    % save data
    % catch error
catch MY_ERROR
    rethrow(MY_ERROR);
end