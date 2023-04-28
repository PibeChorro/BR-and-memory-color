%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main script for a binocular rivalry (BR) experiment using images of
% objects in either their "correct" - i.e., associated - color or in an
% "incorrect" color - i.e., a color normally not associated with the
% object.
% Data of interest: onset dominance (first dominant percept), sustained
% dominance (time each stimulus is perceived), number of switches, duration
% of initial percept
% Written by Vincent Plikat 13/04/2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Variables
% Constant variables

% design related
numRuns     = 0;
numTrials   = 0;
numBreaks   = 0;

stimulusPresentationTime    = 2;
ITI                         = 1;

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
imageFileEnding = '.png';

% data related
dataDir = fullfile('..', '..', 'rawdata');

% Dynamic variables
% design related
task = '';              % there probably will be more than one condition

% data related
% results table
% TODO: add primer - grayscaled image of stimulus?
% stimulus  | true-eye  | stim-onset    | stim-offset   | init-perc | duration-init | duration-true | duration-invert   | duration-mixed    | num-switches  |
% string    | string    | float         | float         | string    | float         | float         | float             | float             | int           |
% Example
% frog_1    | right     | 12.345        | 17.890        | true_color| 2.22          | 3.1           | 1.9               | 0.5               | 3             |
% ....
%
subjectData = table; % or maybe a cell array?
% preallocate data
stimuli         = {
    'green_frog_1';...
    'red_tomato'; ...
    'yellow_banana';...
    'orange_mandarine'
    };   % read out from an existing condition table
trueEye         = {'right','left','left','right'};   % read out from an existing condition table
stimOnset       = zeros(4,1);
stimOffset      = zeros(4,1);
initPercept     = {'','','',''};
durationInit    = zeros(4,1);
durationTrue    = zeros(4,1);
durationInvert  = zeros(4,1);
durationMixed   = zeros(4,1);
numSwitches     = zeros(4,1);

% the exact times of which button was pressed at which point. Cannot be
% preallocated because we do not know how many switches may occur
log.data.idDown     = [];
log.data.timeDown   = [];
log.data.idUp       = [];
log.data.timeUp     = [];

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

        % imread does not read in the alpha channel by default. We need to
        % get it from the third return value and add to the img
        [img1, ~, alpha1] = imread(trueColorStim);
        [img2, ~, alpha2] = imread(invertedColorStim);
        img1(:,:,4) = alpha1;
        img2(:,:,4) = alpha2;
        % Get an initial screen flip for timing
        vbl = Screen('Flip', ptb.window);
        % Draw the image to the screen, unless otherwise specified PTB will draw
        % the texture full size in the center of the screen. We first draw the
        % image in its correct orientation.
        
        % Select   left-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, 0);
        imageTexture1 = Screen('MakeTexture', ptb.window, img1);
        Screen('DrawTexture', ptb.window, imageTexture1);
        % Select right-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, 1);
        imageTexture2 = Screen('MakeTexture', ptb.window, img2);
        Screen('DrawTexture', ptb.window, imageTexture2);
        % Tell PTB drawing is finished for this frame:
        Screen('DrawingFinished', ptb.window);

        % Present stimuli
        vblOnset  = Screen('Flip', ptb.window);
        
        % get subject input during trial

        % show intertrial interval
        vblOffset = Screen('Flip', ptb.window, vblOnset+stimulusPresentationTime);
        WaitSecs(ITI);
        % save timing of stimuli
        stimOnset(stim) = vblOnset-ExpStart;
        stimOffset(stim) = vblOffset-ExpStart;
    end

    sca
    
    %% End of experiment
    % save data
    % catch error
catch MY_ERROR
    rethrow(MY_ERROR);
end