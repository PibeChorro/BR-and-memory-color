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
% Varialbes read out by the system and specific to the hardware
try
    ptb = PTBSettings();
catch PTBError
    fprinf('Something went wrong setting up PTB');
    rethrow(PTBError)
end
% Constant variables

% design related
numRuns     = 0;
numTrials   = 0;
numBreaks   = 0;

stimulusPresentationTime    = 2 - ptb.ifi/2;
ITI                         = 1 - ptb.ifi/2;

% hardware related
distToMonitor = 0;
monitorWidth = 0;
monitorHeight = 0;

keys = [];
ptb.useET = false;

% stimuli related
stimDirectory = fullfile('..', '..', 'stimuli');
trueColorDirectory = fullfile(stimDirectory, 'true_color');
invertedColorDirectory = fullfile(stimDirectory, 'inverted');
imageFileEnding = '.png';
checkerBoardXFrequency = 8;     % checkerboard background frequency along X
checkerBoardYFrequency = 8;     % checkerboard background frequency along Y

% data related
dataDir = fullfile('..', '..', 'rawdata');

% Dynamic variables
% Stimuli related
imageXPixels = 0;       % later read out from an example
imageYPixels = 0;       % later read out from an example
% design related
ExpStart = 0;         % GetSecs later to set the onset of all the experiment
TrialEnd = 0;         % For better timing
% design related
task = '';              % there probably will be more than one condition
trueColorBufferId       = 0; % 0=left; 1=right - just for initialization 
invertedColorBufferId   = 1; % 0=left; 1=right - just for initialization

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
% get randomized stimulus conditions
[log.data.trueEye, log.data.stimuli]  = createCounterbalancedPseudorandomizedConditions(trueColorDirectory);

% get number of trials from the length of stimuli 
numTrials = length(log.data.trueEye);
% trueEye is a cell array containing either 'right' or 'left' -> convert
% into 0 and 1 for easy and fast assignment
log.data.trueEyeBinary = zeros(numTrials,1);
for side = 1:length(log.data.trueEye)
    if strcmp(log.data.trueEye{side}, 'left')
        log.data.trueEyeBinary(side) = 0;
    elseif strcmp(log.data.trueEye{side}, 'right')
        log.data.trueEyeBinary(side) = 1;
    else
        error('Assignment for true color side is neither left nor right')
    end
end

% preallocate data
log.data.stimOnset           = zeros(numTrials,1);
log.data.stimOffset          = zeros(numTrials,1);
log.data.initPercept         = repmat({''},numTrials,1);
log.data.durationInit        = zeros(numTrials,1);
log.data.durationTrue        = zeros(numTrials,1);
log.data.durationInvert      = zeros(numTrials,1);
log.data.durationMixed       = zeros(numTrials,1);
log.data.numSwitches         = zeros(numTrials,1);

% the exact times of which button was pressed at which point. Cannot be
% preallocated because we do not know how many switches may occur
log.data.idDown     = [];
log.data.timeDown   = [];
log.data.idUp       = [];
log.data.timeUp     = [];

% read in one example image to get the size and then create a checkerboard
% as background
exampleImgPath = fullfile(trueColorDirectory, log.data.stimuli{1});
exampleImg = imread(exampleImgPath);
imageSize = size(exampleImg);
imageXPixels = imageSize(1);
imageYPixels = imageSize(2);

checkerBoardBackground = createCheckerboard(imageXPixels, imageYPixels,...
    checkerBoardXFrequency, checkerBoardYFrequency);
backGroundTexture = Screen('MakeTexture', ptb.window, checkerBoardBackground);

% resize stimuli
% define a rectangle where the stimulus is drawn
ptb.destinationRect = [ptb.screenXpixels/2-128 ptb.screenYpixels/2-128 ...
    ptb.screenXpixels/2+128 ptb.screenYpixels/2+128];

% big frame around stimuli
bigFrame = [0+50, 0+50, ptb.screenXpixels-50, ptb.screenYpixels-50];
penWidth = 10;

log.fileName = 'test';      % TODO

try
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

    %% Stop and remove events in queue
    KbQueueStop(ptb.Keyboard2);
    KbEventFlush(ptb.Keyboard2);
    KbQueueStop(ptb.Keyboard1);
    KbEventFlush(ptb.Keyboard1);

    % restart KbQueues
    KbQueueStart(ptb.Keyboard2); % Subjects
    KbQueueStart(ptb.Keyboard1); % Experimentors

    %% Presentation of stimuli
    ExpStart = GetSecs();
    TrialEnd = ExpStart;
    
    % Loop over trials
    for trial = 1:2 %length(numTrials)
        trueColorStimPath = fullfile(trueColorDirectory, log.data.stimuli{trial});
        invertedColorStimPath = fullfile(invertedColorDirectory, log.data.stimuli{trial});
        % imread does not read in the alpha channel by default. We need to
        % get it from the third return value and add to the img
        [trueColorStimImg, ~, trueAlpha]            = imread(trueColorStimPath);
        [invertedColorStimImg, ~, invertedAlpha]    = imread(invertedColorStimPath);
        trueColorStimImg(:,:,4)         = trueAlpha;
        invertedColorStimImg(:,:,4)     = invertedAlpha;
        
        % Determine on which eye the true color and the inverted color
        % stimulus is presented 
        trueColorBufferId       = sum(log.data.trueEyeBinary(trial));
        invertedColorBufferId   = sum(~log.data.trueEyeBinary(trial));

        % Select   left-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, trueColorBufferId);
        Screen('FrameRect', ptb.window ,ptb.black ,bigFrame, penWidth);
        Screen('DrawTexture', ptb.window, backGroundTexture);
        trueColorTexture = Screen('MakeTexture', ptb.window, trueColorStimImg);
        Screen('DrawTexture', ptb.window, trueColorTexture, [], ptb.destinationRect);
        % Select right-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, invertedColorBufferId);
        Screen('FrameRect', ptb.window ,ptb.black ,bigFrame, penWidth);
        Screen('DrawTexture', ptb.window, backGroundTexture);
        invertedColorTexture = Screen('MakeTexture', ptb.window, invertedColorStimImg);
        Screen('DrawTexture', ptb.window, invertedColorTexture, [], ptb.destinationRect);
        % Tell PTB drawing is finished for this frame:
        Screen('DrawingFinished', ptb.window);

        % Present stimuli
        vblOnset  = Screen('Flip', ptb.window, TrialEnd + ITI);

        % show intertrial interval
        vblOffset   = Screen('Flip', ptb.window, vblOnset+stimulusPresentationTime);
        TrialEnd    = vblOffset;

        % save timing of stimuli
        log.data.stimOnset(trial)     = vblOnset-ExpStart;
        log.data.stimOffset(trial)    = vblOffset-ExpStart;
        %... Check if Experimentors pressed escape ...%
        % DOES NOT WORK!!!
        [pressed, firstPress] = KbQueueCheck(ptb.Keyboard1);
        if pressed
            if firstPress(ptb.Keys.escape)
                log.end = 'Escape'; % Finished by escape key
                log.ExpNotes = input('Notes:','s');
                savedata(log,ptb);
                warning('Experiment was terminated by Escapekey');
                return;
            end
        end
    end

    sca
    % Experiment ended without errors
    log.end = 'Success';
    savedata(log,ptb);
    
    %% End of experiment
    % save data
    % catch error
catch MY_ERROR
    sca
    % Experiment ended with an error
    log.end = 'Finished with errors';
    savedata(log,ptb);
    rethrow(MY_ERROR);
end