%% Variables
% Varialbes read out by the system and specific to the hardware
try
    ptb = PTBSettings();
catch PTBError
    fprintf('Something went wrong setting up PTB!\n');
    rethrow(PTBError)
end

%% design related
design.stimulusPresentationTime = 12 - ptb.ifi/2;
design.ITI                      = 5 - ptb.ifi/2;
design.stimSizeInDegrees        = 5;
design.stimSizeInPixels         = round(ptb.PixPerDegWidth*design.stimSizeInDegrees);
design.grayBackgroundInDegrees  = 6;
design.checkerBoardInDegrees    = 10;
design.checkerBoardXFrequency   = 8;     % checkerboard background frequency along X
design.checkerBoardXFrequency   = 8;     % checkerboard background frequency along Y
design.angle                    = 45; % angle
design.frequency                = 0.03; % spatial frequency
design.contrast                 = 0.5; % contrast 
design.sigma                    = -1.0; % sigma < 0 is a sinusoid.

% Use eyetracker?
design.useET = false;

%% experimenter input
dataDir = fullfile('..', '..', 'rawdata');
subNr = input('Enter subject Nr: ','s');
correctRunInput = false;

sub = strcat('sub-', sprintf('%02s', subNr));
% read in log mat file
try
    load(fullfile(dataDir, sub, [sub 'logFile.mat']))
catch LOADING_ERROR
    fprintf('No log file was found. Either you did not perform the flicker method or you typed in the wrong subject Number\n')
    loadDefault = input('Do you want to load a standard subject Y/N [Y]? ','s');
    if (strcmp(loadDefault, 'n') || isempty(loadDefault))
        error('No log was found and you chose not to use a standard subject')
    else
        error('Standard subject is not implemented yet')
    end
end

correctRunInput = false;
% check run input
while ~correctRunInput
    runNr = input('Enter run  Nr [1-6]:', 's');
    [runNr,isNumber] = str2num(runNr);
    if isNumber && runNr>0 && runNr<=6
        correctRunInput = true;
    end
end

log.task = 'gratings';
log.runNr = runNr;

colorDirectory = fullfile(log.subjectDirectory,'stimuli','typical_colors.csv');
% read in table with typical colors
try
    typicalColorTable = readtable(colorDirectory);
catch READINGERROR
    fprintf('Could not read the color table\n\n');
    rethrow(READINGERROR)
end

% read in csv table with conditions for run
try
    conditionsTableDir = fullfile(log.subjectDirectory,[log.sub sprintf('_run-%02d',log.runNr) '.csv']);
    conditionsTable = readtable(conditionsTableDir,'Delimiter', ',');
catch READINGERROR
    error('could not read conditions table')
end
log.data.trueEye = conditionsTable.sides;
log.data.stimuli = conditionsTable.stimuli;

%% data
% the exact times of which button was pressed at which point. Cannot be
% preallocated because we do not know how many switches may occur
log.data.idDown     = [];
log.data.timeDown   = [];
log.data.idUp       = [];
log.data.timeUp     = [];

%% better timing
log.ExpStart = 0;     % GetSecs later to set the onset of all the experiment
TrialEnd = 0;         % For better timing
% design related


%% Subject input
try
    fprintf (log.sub);
    fprintf ('\n');
    fprintf (log.subjectDirectory);
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
    
    ListenChar(2); % suppress input to matlab windows
    %% Actual experiment
    % fuse images to the eyes
    % Do this before anything else
    [design.xOffset, design.yOffset] = alignFusion(ptb, design);

    %% Instructions
    if log.runNr == 1
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
        DrawFormattedText (ptb.window, design.InstructionGratings1, 'center', 'center',ptb.FontColor);
        % Select right-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, 1);
        DrawFormattedText (ptb.window, design.InstructionGratings1, 'center', 'center',ptb.FontColor);
        % Tell PTB drawing is finished for this frame:
        Screen('DrawingFinished', ptb.window);
        Screen ('Flip', ptb.window);
        WaitSecs (0.5);
        KbWait();
        
        % Select   left-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, 0);
        DrawFormattedText (ptb.window, design.InstructionGratings2, 'center', 'center',ptb.FontColor);
        % Select right-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', ptb.window, 1);
        DrawFormattedText (ptb.window, design.InstructionGratings2, 'center', 'center',ptb.FontColor);
        % Tell PTB drawing is finished for this frame:
        Screen('DrawingFinished', ptb.window);
        Screen ('Flip', ptb.window);
        WaitSecs (0.5);
        KbWait();
    end
    
    % Select   left-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, 0);
    DrawFormattedText (ptb.window, design.InstructionGratings3, 'center', 'center',ptb.FontColor);
    % Select right-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, 1);
    DrawFormattedText (ptb.window, design.InstructionGratings3, 'center', 'center',ptb.FontColor);
    % Tell PTB drawing is finished for this frame:
    Screen('DrawingFinished', ptb.window);
    Screen ('Flip', ptb.window);
    WaitSecs (0.5);
    KbWait();
    
    % Select   left-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, 0);
    DrawFormattedText (ptb.window, design.waitTillStart, 'center', 'center',ptb.FontColor);
    % Select right-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, 1);
    DrawFormattedText (ptb.window, design.waitTillStart, 'center', 'center',ptb.FontColor);
    % Tell PTB drawing is finished for this frame:
    Screen('DrawingFinished', ptb.window);
    vbl = Screen ('Flip', ptb.window);
    
    %% Stop and remove events in queue
    KbQueueStop(ptb.Keyboard2);
    KbEventFlush(ptb.Keyboard2);
    KbQueueStop(ptb.Keyboard1);
    KbEventFlush(ptb.Keyboard1);

    % restart KbQueues
    KbQueueStart(ptb.Keyboard2); % Subjects
    KbQueueStart(ptb.Keyboard1); % Experimentors

    %% Presentation of stimuli
    log.ExpStart = GetSecs();
    TrialEnd = log.ExpStart;

    % Loop over trials
    for trial = 1:2%:numTrials
        % show gratings
        phase = 0; % phase
        idx = find(typicalColorTable.stimuli == conditionsTable.stimuli(trial));
        trueR = typicalColorTable.true_r(idx);
        trueG = typicalColorTable.true_g(idx);
        trueB = typicalColorTable.true_b(idx);

        invR = typicalColorTable.inv_r(idx);
        invG = typicalColorTable.inv_g(idx);
        invB = typicalColorTable.inv_b(idx);

        trueColor = [trueR trueG trueB 1]/255;
        invertedColor = [invR invG invB 1]/255;
        
        black = [0 0 0 1];

        trueColorBufferId = 0;
        invertedColorBufferId = 1;

        %% draw and show stimuli
        % Build a procedural texture, we also keep the shader as we will show how to
        % modify it (though not as efficient as using parameters in drawtexture)
        trueGrating = CreateProceduralColorGrating(ptb.window, design.stimSizeInPixels, ...
            design.stimSizeInPixels,trueColor, black, design.stimSizeInPixels/2);

        invGrating = CreateProceduralColorGrating(ptb.window, design.stimSizeInPixels, ...
            design.stimSizeInPixels,invertedColor, black, design.stimSizeInPixels/2);
             
        % tell subjects which button they should press, depending on their
        % percept
        
        % Select image buffer for the left eye:
        Screen('SelectStereoDrawBuffer', ptb.window, 0);
        DrawFormattedText(ptb.window, design.trueExampleText, ...
            ptb.screenXpixels/8,ptb.yCenter-design.stimSizeInPixels*2,ptb.FontColor);
        DrawFormattedText(ptb.window, design.invExampleText, ...
            ptb.screenXpixels/2,ptb.yCenter-design.stimSizeInPixels*2,ptb.FontColor);
        
        DrawFormattedText(ptb.window, design.proceedText, ptb.xCenter/2, ...
            ptb.screenYpixels*3/4, ptb.FontColor); 
        
        Screen('DrawTexture', ptb.window, trueGrating, [], trueExampleRect, ...
                design.angle, [], [], ptb.BackgroundColor, [], [], ...
                [phase, design.frequency, design.contrast, design.sigma]);    
        Screen('DrawTexture', ptb.window, invGrating, [], invExampleRect, ...
                -design.angle, [], [], ptb.BackgroundColor, [], [], ...
                [phase, design.frequency, design.contrast, design.sigma]);
        
        % Select image buffer for the right eye:
        Screen('SelectStereoDrawBuffer', ptb.window, 1);
        DrawFormattedText(ptb.window, design.trueExampleText, ...
            ptb.screenXpixels/8,ptb.yCenter-design.stimSizeInPixels*2,ptb.FontColor);
        DrawFormattedText(ptb.window, design.invExampleText, ...
            ptb.screenXpixels/2,ptb.yCenter-design.stimSizeInPixels*2,ptb.FontColor);
        
        DrawFormattedText(ptb.window, design.proceedText, ptb.xCenter/2, ...
            ptb.screenYpixels*3/4, ptb.FontColor); 
        
        Screen('DrawTexture', ptb.window, trueGrating, [], trueExampleRect, ...
                design.angle, [], [], ptb.BackgroundColor, [], [], ...
                [phase, design.frequency, design.contrast, design.sigma]);    
        Screen('DrawTexture', ptb.window, invGrating, [], invExampleRect, ...
                -design.angle, [], [], ptb.BackgroundColor, [], [], ...
                [phase, design.frequency, design.contrast, design.sigma]);
        
        % Tell PTB drawing is finished for this frame:
        Screen('DrawingFinished', ptb.window);

        % get initial flip timing
        vbl = Screen('Flip',ptb.window, vbl + design.ITI);
        
        KbWait();
        log.data.stimOnset(trial) = GetSecs();
        while vbl < log.data.stimOnset(trial) + design.stimulusPresentationTime
            % Select image buffer for true color image:
            Screen('SelectStereoDrawBuffer', ptb.window, trueColorBufferId);
            % Draw the shader texture with parameters
            Screen('DrawTexture', ptb.window, trueGrating, [], [], ...
                design.angle, [], [], ptb.BackgroundColor, [], [], ...
                [phase, design.frequency, design.contrast, design.sigma]);

            % Select image buffer for inverted color image:
            Screen('SelectStereoDrawBuffer', ptb.window, invertedColorBufferId);
            % Draw the shader texture with parameters
            Screen('DrawTexture', ptb.window, invGrating, [], [], ... 
                -design.angle, [], [], ptb.BackgroundColor, [], [], ...
                [phase, design.frequency, design.contrast, design.sigma]);
            % Tell PTB drawing is finished for this frame:
            Screen('DrawingFinished', ptb.window);
            vbl = Screen('Flip', ptb.window, vbl + 0.5 * ptb.ifi);

            % update phase
            phase = phase - 15;
        end

        % close textures to save memory
        Screen('Close', trueGrating);
        Screen('Close', invGrating);

        % show intertrial interval
        endTrial = Screen('Flip', ptb.window);
        WaitSecs(design.ITI);


        %% save timing of stimuli
        log.data.stimOffset(trial)    = endTrial;
    end
    
    % Run is over
    % Select   left-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, 0);
    DrawFormattedText (ptb.window, design.RunIsOver, 'center', 'center',ptb.FontColor);
    % Select right-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', ptb.window, 1);
    DrawFormattedText (ptb.window, design.RunIsOver, 'center', 'center',ptb.FontColor);
    % Tell PTB drawing is finished for this frame:
    Screen('DrawingFinished', ptb.window);
    Screen ('Flip', ptb.window);
    WaitSecs (0.5);
    KbWait();

    Screen('CloseAll');
    ListenChar(1);
    % Experiment ended without errors
    log.end = 'Success';
    % save data
    log = savedata(log,ptb,design);

catch MY_ERROR
    Screen('CloseAll');
    ListenChar(1); % enable input to matlab windows
    % Experiment ended with an error
    rethrow(MY_ERROR);
end