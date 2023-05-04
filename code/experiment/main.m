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

%% design related
design.stimulusPresentationTime    = 2 - ptb.ifi/2;
design.ITI                         = 1 - ptb.ifi/2;
design.stimSizeInDegrees           = 5;
design.stimSizeInPixels            = round(ptb.PixPerDegWidth*design.stimSizeInDegrees);
design.grayBackgroundInDegrees     = 6;
design.checkerBoardInDegrees       = 10;
design.checkerBoardXFrequency      = 8;     % checkerboard background frequency along X
design.checkerBoardXFrequency      = 8;     % checkerboard background frequency along Y
% Use eyetracker?
design.useET = false;

%% stimuli related
stimDirectory = fullfile('..', '..', 'stimuli');
trueColorDirectory = fullfile(stimDirectory, 'true_color');
invertedColorDirectory = fullfile(stimDirectory, 'inverted');

% resize stimuli
% define a rectangle where the stimulus is drawn
ptb.destinationRect = [...
    ptb.screenXpixels/2-design.stimSizeInPixels/2 ... 
    ptb.screenYpixels/2-design.stimSizeInPixels/2 ...
    ptb.screenXpixels/2+design.stimSizeInPixels/2 ...
    ptb.screenYpixels/2+design.stimSizeInPixels/2];

%% Backgrounds
% gray small background
design.grayBackgroundInPixelsX     = round(ptb.PixPerDegWidth* 2 *design.grayBackgroundInDegrees); 
design.grayBackgroundInPixelsY     = round(ptb.PixPerDegHeight*design.grayBackgroundInDegrees);
ptb.grayRect = [...
    ptb.screenXpixels/2-design.grayBackgroundInPixelsX/2 ... 
    ptb.screenYpixels/2-design.grayBackgroundInPixelsY/2 ...
    ptb.screenXpixels/2+design.grayBackgroundInPixelsX/2 ...
    ptb.screenYpixels/2+design.grayBackgroundInPixelsY/2];
% checkerboard background
% IMPORTANT! because the screen is in Stereomode and therefore devided the
% calculation for pixel width is wrong. Multiplying by 2 resovles that
design.checkerBoardInPixelsX       = int16(round(ptb.PixPerDegWidth* 2 *design.checkerBoardInDegrees));
design.checkerBoardInPixelsY       = int16(round(ptb.PixPerDegHeight*design.checkerBoardInDegrees));
checkerBoardBackground = createCheckerboard(design.checkerBoardInPixelsX, design.checkerBoardInPixelsY,...
    design.checkerBoardXFrequency, design.checkerBoardXFrequency);
backGroundTexture = Screen('MakeTexture', ptb.window, checkerBoardBackground);
% big frame around stimuli
design.bigFrame = [0+50, 0+50, ptb.screenXpixels-50, ptb.screenYpixels-50];
design.penWidth = 10;

%% data related
% results table
% TODO: add primer - grayscaled image of stimulus?
% stimulus  | true-eye  | stim-onset    | stim-offset   | init-perc | duration-init | duration-true | duration-invert   | duration-mixed    | num-switches  |
% string    | string    | float         | float         | string    | float         | float         | float             | float             | int           |
% Example
% frog_1    | right     | 12.345        | 17.890        | true_color| 2.22          | 3.1           | 1.9               | 0.5               | 3             |
% ....
%
dataDir = fullfile('..', '..', 'rawdata');
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

%% better timing
ExpStart = 0;         % GetSecs later to set the onset of all the experiment
TrialEnd = 0;         % For better timing
% design related
trueColorBufferId       = 0; % 0=left; 1=right - just for initialization 
invertedColorBufferId   = 1; % 0=left; 1=right - just for initialization

%% Subject input
try
    [log.sub, log.subjectDir, log.language] = inputSubID(dataDir, ptb);
    fprintf (log.sub);
    fprintf ('\n');
    fprintf (log.subjectDir);
    fprintf ('\n');
    
    %% Get design settings
    design = designSettings(log.language,design);
    
    %% Inclusion of eye tracker
    if design.useET
        ET = IncludeEyetracker(log.sub);
        % Calibration and Validation
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
    [design.xOffset, design.yOffset] = alignFusion(ptb, design);

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
        Screen('FillRect', ptb.window, ptb.grey, grayRect);
        trueColorTexture = Screen('MakeTexture', ptb.window, trueColorStimImg);
        Screen('DrawTexture', ptb.window, trueColorTexture, [], ptb.destinationRect);

        % Select right-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, invertedColorBufferId);
        Screen('FrameRect', ptb.window ,ptb.black ,bigFrame, penWidth);
        Screen('DrawTexture', ptb.window, backGroundTexture);
        Screen('FillRect', ptb.window, ptb.grey, grayRect);
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
                savedata(log,ptb,design);
                warning('Experiment was terminated by Escapekey');
                return;
            end
        end
    end

    %% End of experiment
    Screen('CloseAll')
    % Experiment ended without errors
    log.end = 'Success';
    % save data
    savedata(log,ptb,design);
    
% catch error
catch MY_ERROR
    Screen('CloseAll')
    % Experiment ended with an error
    log.end = 'Finished with errors';
    savedata(log,ptb,design);
    rethrow(MY_ERROR);
end