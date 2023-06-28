function isolumFlickerMethod()
% get equiluminant colors using the flicker method
% The function reads in a table with RGB values of diagnostic colors for a
% set of stimlui and the corresonding RGB values of the inverted color in
% CIELab* space.
% Each color is presented with its inversion and luminance can be adjusted
% until the colored rectangles do not flicker anymore (i.e., they are
% equiluminant
% The resulting table is then saved in the subject directory

% get all the important setting information
PsychDefaultSetup(2);
ptb = PTBSettings();
% create subject directory to save equiluminance table
log = struct;
log.dataDir = fullfile('..', '..', 'rawdata');
log = inputSubID(ptb,log);

KbName('UnifyKeyNames');
% Define response buttons
terminateButton     = ptb.Keys.escape;
lumIncreaseButton   = ptb.Keys.left;
lumDecreaseButton   = ptb.Keys.right; 
confirmButton       = ptb.Keys.accept; % Space

% read in setup specific gamma correction table
switch ptb.SetUp
    case 'CIN-personal'
        LUT = readmatrix('gammaLUT.txt'); % lookup table to make monitor linear
    case 'CIN-experimentroom'
        monCalDir = fullfile('..', 'monitor_calibration', 'EIZO_CIN5th_Brightness50_SpectraScan670_derived.mat');
        load(monCalDir);
        LUT = round(cal.iGammaTable*255);
%         LUT = textread('spc_mrz3t_gammaLUT.txt'); % img_gammaLUT(gamma_mon,1); % lookup table to make monitor linear
    case 'MPI'
        LUT = textread('spc_mrz3t_gammaLUT.txt'); % img_gammaLUT(gamma_mon,1); % lookup table to make monitor linear
    otherwise
        error('No valid setup choise')
end


%% get all stimuli 
stimDir = fullfile('..', '..', 'stimuli');
trueColorStimulDir = fullfile(stimDir,'true_color');
invertedColorStimDir = fullfile(stimDir,'inverted_lab');
maskDir = fullfile(stimDir,'color_masks');
stimulusSelection = {
    'blue_nivea.png' ...
    'blue_pool.png' ...
    'blue_sign.png' ...
    'green_brokkoli_1.png' ...
    'green_frog_1.png' ... 
    'green_lettuce_1.png' ...
    'orange_basketball.png' ...
    'orange_carrots.png' ... 
    'orange_pumpkin.png' ...
    'red_fire_extinguisher_1.png' ...
    'red_strawberry.png' ...
    'red_tomato.png' ...
    'yellow_banana.png' ...
    'yellow_chicken.png' ...
    'yellow_corn.png'
};
% shuffle stimuli order
stimulusSelection = Shuffle(stimulusSelection);
numStimuli = length(stimulusSelection);

% get maximum number of pixels within mask
maxPixel = 1;
for i = 1:numStimuli
    % read in stimulus mask
    curMask = imread(fullfile(maskDir,stimulusSelection{i}));
    curPixels = sum(sum(curMask(:,:,1)>0));
    if curPixels>maxPixel
        maxPixel = curPixels;
    end
end

% get square root of maximal pixels to create a square with scrambled
% pixels
colorPatchSize = ceil(sqrt(maxPixel));
% get number of pixels in color patch
numPixels = colorPatchSize*colorPatchSize;

% create subject stimuli directories to store the resulting stimuli in
correctedTrueStimDir = fullfile(log.subjectDirectory,'stimuli','true_color');
if (~isfolder(correctedTrueStimDir))
    mkdir(correctedTrueStimDir);
end
correctedFalseStimDir = fullfile(log.subjectDirectory,'stimuli','inverted_lab');
if (~isfolder(correctedFalseStimDir))
    mkdir(correctedFalseStimDir);
end


% stepsize with which the luminance should be increased/decreased
stepSize = 1/255;

lum = 255;

% align fusion
design = designSettings(log.language);
alignFusion(ptb, design);

% Prepare instruction screen
if strcmp(log.language,'german')
    instructionStr = sprintf(['HELLIGKEITS ANPASSUNG\n\n' ...
        'Im Folgenden wirst du eine Reihe\n' ...
        'farbiger, flackernder Rechtecke sehen,\n' ...
        'Deine Aufgabe ist es, \n' ...
        'mit den Tasten "4" und "6" die Helligkeit so zu ändern,\n'...
        'dass die Rechtecke so wenig\n ' ...
        'flackern wie möglich.' ...
        'Wenn du glaubst das Flackern\n' ...
        'minimiert zu haben, drücke die "5" Taste.\n\n' ...
        'Diese Aufgabe wird 15 Mal wiederholt und dauert ca. 5 Minuten.\n\n' ...
        'DRÜCKE DIE "5" UM ZU STARTEN']);
else
    instructionStr = sprintf(['LUMINANCE ADJUSTMENT\n\n'...
        'In the following task\n' ...
        'you will be shown a series of \n' ...
        'colored flickering color patches.\n'...
        'The goal of this task is to change \n' ...
        'the luminance of each patch such that the\n'...
        'flickering is minimized\n' ... 
        'using the "4" and "6" button.\n\n'...
        'If you think that minimal flickering\n' ... 
        'has been achieved, press the "5" button\n'...
        'This task is repeated 15 times and takes about 5 minutes.\n\n'...
        'PRESS THE "5" KEY TO PROCEED']);
end

% Select   left-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', ptb.window, 0);
% Screen('FillRect', ptb.window, img_gammaConvert(LUT,round(ones(1,3)*lum*.5)), [0 100 100 200]);
DrawFormattedText(ptb.window, instructionStr, 'center', 'center', [255 255 0]);
% Select   left-eye image buffer for drawing:
Screen('SelectStereoDrawBuffer', ptb.window, 1);
% Screen('FillRect', ptb.window, img_gammaConvert(LUT,round(ones(1,3)*lum*.5)));
DrawFormattedText(ptb.window, instructionStr, 'center', 'center', [255 255 0]);
Screen('DrawingFinished', ptb.window);

while KbCheck;end

% Disable keyboard output to Matlab
% ListenChar(2);

% Do initial flip and show instructions    
vbl = Screen('Flip', ptb.window);

KbWait();
WaitSecs(0.5);

% Flush Keyevents in order to avoid that a buttonpress is already
% interpreted as a reaction to the task
KbEventFlush()
% Iterate over all colors that need to be adjusted
for curStim = 1:numStimuli
    trueOutputDir = fullfile(correctedTrueStimDir,stimulusSelection{curStim});
    invOutputDir = fullfile(correctedFalseStimDir,stimulusSelection{curStim});
    
    %% read in stimuli
    % true color
    [trueColorStim, ~, trueAlpha] = imread(fullfile(trueColorStimulDir,stimulusSelection{curStim}));
    % inverted color
    [invertedColorStim, ~, invAlpha] = imread(fullfile(invertedColorStimDir,stimulusSelection{curStim}));
    % mask
    curMask = imread(fullfile(maskDir,stimulusSelection{curStim}));
    % get pixels within mask
    objectPixels = curMask(:,:,1)>0;
    indices = find(objectPixels);

    curPixels = sum(sum(objectPixels));
    numGreyPixels = numPixels - curPixels;

    trueR = trueColorStim(:,:,1);
    trueG = trueColorStim(:,:,2);
    trueB = trueColorStim(:,:,3);
    truePixels = zeros(length(trueColorStim(objectPixels)),3);
    truePixels(:,1) = trueR(objectPixels);
    truePixels(:,2) = trueG(objectPixels);
    truePixels(:,3) = trueB(objectPixels);

    invR = invertedColorStim(:,:,1);
    invG = invertedColorStim(:,:,2);
    invB = invertedColorStim(:,:,3);
    invPixels = zeros(length(invertedColorStim(objectPixels)),3);
    invPixels(:,1) = invR(objectPixels);
    invPixels(:,2) = invG(objectPixels);
    invPixels(:,3) = invB(objectPixels);

    % store original pixel location

    % get number of pixels we need to fill with gray pixels
    curTrueLumFactor = [1 1 1]; 
    curFalseLumFactor = [1 1 1];
    maxCurTrueLumFactor = 255./max(truePixels);
    maxCurFalseLumFactor = 255./max(invPixels);
    
    curFrame = 1;
    spaceDown = 0;  % Has P pressed the space bar?
    responseKeyReleased = 1;    % Has P released response key?
    tic
    % Color adjustment
    while ~spaceDown
        if curFrame > 1
            % Set the gamma corrected color values
            correctedTrueColor = img_gammaConvert(LUT,round(truePixels.*curTrueLumFactor)/lum);
            correctedFalseColor = img_gammaConvert(LUT,round(invPixels.*curFalseLumFactor)/lum);
            fprintf('Gamma correction\n');
            toc
            truePlusGreyPixels = correctedTrueColor;
            invPlusGreyPixels = correctedFalseColor;

            % add grey pixels to make it a square
            truePlusGreyPixels(end:end+numGreyPixels,:) = ptb.grey;
            invPlusGreyPixels(end:end+numGreyPixels,:) = ptb.grey;
            fprintf('bla Hardik sucks balls\n');

            % reshape into a square
            trueColorPatch = reshape(truePlusGreyPixels,[colorPatchSize colorPatchSize 3]);
            invColorPatch = reshape(invPlusGreyPixels,[colorPatchSize colorPatchSize 3]);
            fprintf('Creation of colorpatch\n');
            toc

            % Select   left-eye image buffer for drawing:
            Screen('SelectStereoDrawBuffer', ptb.window, 0);
            if mod(curFrame,2) == 1 % Inversed color
                leftStimTexture = Screen('MakeTexture', ptb.window, invColorPatch);     % create texture for stimulus
                Screen('DrawTexture', ptb.window, leftStimTexture)
            elseif mod(curFrame,2) == 0 % True color
                leftStimTexture = Screen('MakeTexture', ptb.window, trueColorPatch);         % create texture for stimulus
                Screen('DrawTexture', ptb.window, leftStimTexture)
            end
            fprintf('Draw to buffer 0\n');
            toc

            % Select   right-eye image buffer for drawing:
            Screen('SelectStereoDrawBuffer', ptb.window, 1);
            if mod(curFrame,2) == 1 % Inversed color
                rightStimTexture = Screen('MakeTexture', ptb.window, invColorPatch);     % create texture for stimulus
                Screen('DrawTexture', ptb.window, rightStimTexture)
            elseif mod(curFrame,2) == 0 % True color
                rightStimTexture = Screen('MakeTexture', ptb.window, trueColorPatch);         % create texture for stimulus
                Screen('DrawTexture', ptb.window, rightStimTexture)
            end
            fprintf('Draw to buffer 1\n');
            toc

            Screen('DrawingFinished', ptb.window); % Tell PTB that no further drawing commands will follow before Screen('Flip')
            % close stimulus texture
            Screen('Close', rightStimTexture);
            Screen('Close', leftStimTexture);
            fprintf('Closing textures\n');
            toc
        end
    
        % Record and process responses
        [ keyIsDown, ~, keyCode ] = KbCheck;
        if responseKeyReleased == 1 && keyIsDown == 1
            responseKeyReleased = 0;
            keyId = find(keyCode);
            switch keyId(1) % If, accidentally, multiple keys were pressed, choose the one with the lower ID
                   
                case terminateButton
                    break   % User terminated execution by pressing ESC               

                case lumIncreaseButton
                    curTrueLumFactor = curTrueLumFactor+stepSize;
                    curFalseLumFactor = curFalseLumFactor-stepSize;

                case lumDecreaseButton
                    curTrueLumFactor = curTrueLumFactor-stepSize;
                    curFalseLumFactor = curFalseLumFactor+stepSize;

                case confirmButton
                    fprintf('Accepted\n')
                    trueR(indices) = uint8(round(correctedTrueColor(:,1)*255));
                    trueG(indices) = uint8(round(correctedTrueColor(:,2)*255));
                    trueB(indices) = uint8(round(correctedTrueColor(:,3)*255));

                    trueColorStim(:,:,1) = trueR;
                    trueColorStim(:,:,2) = trueG;
                    trueColorStim(:,:,3) = trueB;

                    imwrite(trueColorStim,trueOutputDir,'png','Alpha', trueAlpha);

                    invR(indices) = uint8(round(correctedFalseColor(:,1)*255));
                    invG(indices) = uint8(round(correctedFalseColor(:,2)*255));
                    invB(indices) = uint8(round(correctedFalseColor(:,3)*255));

                    invertedColorStim(:,:,1) = invR;
                    invertedColorStim(:,:,2) = invG;
                    invertedColorStim(:,:,3) = invB;

                    imwrite(invertedColorStim, invOutputDir, 'png','Alpha', invAlpha);

                    while KbCheck; end % Wait until all keys have been released
                    spaceDown = 1;    % P confirmed adjustment
            end % switch

            % Make sure the luminance factor does not exceed boundaries
            if any(curTrueLumFactor > maxCurTrueLumFactor)
                curTrueLumFactor(curTrueLumFactor > maxCurTrueLumFactor) = maxCurTrueLumFactor(curTrueLumFactor > maxCurTrueLumFactor); 
            end
            if  any(curFalseLumFactor > maxCurFalseLumFactor) 
                curFalseLumFactor(curFalseLumFactor > maxCurFalseLumFactor) = maxCurFalseLumFactor(curFalseLumFactor > maxCurFalseLumFactor); 
            end
            if any(curTrueLumFactor <= 0)
                curFalseLumFactor(curTrueLumFactor <= 0) = 0;
            end
            if any(curFalseLumFactor <= 0)
                curFalseLumFactor(curFalseLumFactor <= 0) = 0;
            end
        elseif keyIsDown == 0
            responseKeyReleased = 1;
        end % if keyIsDown
        curFrame = curFrame + 1;
        toc
        vbl = Screen('Flip',ptb.window,vbl+ptb.ifi/2);
        tic
    end % while 1
end % for curCol = 1:numel(allProtos)
disp('--------------------------------------------------------------');

