% get all the important setting information
PsychDefaultSetup(2);
ptb = PTBSettings();

% ------------ gamma LUT  -------------
% gamma_mon = textread([path_imgs, 'spc_psyRiv_201003_R_gamma.txt']);

scanning_flag = input('Scanning? (no = 0, yes = 1): ');

if scanning_flag
    
    % Define response buttons
    terminateButton     = 30; % I'm not sure which one this is on the button box
    lumIncreaseButton   = 32; % Button beneath index finger
    lumDecreaseButton   = 33; % Middle finger response
    confirmButton       = 34; % Button on the left side of the box

%     terminateButton     = 30; % I'm not sure which one this is on the button box
%     lumIncreaseButton   = 4; % Button beneath index finger
%     lumDecreaseButton   = 3; % Middle finger response
%     confirmButton       = 5; % Button on the left side of the box

    
    displayWidth        = 800;
    displayHeight       = 600;
        
else
    KbName('UnifyKeyNames');
    % Define response buttons
    terminateButton     = KbName('ESCAPE'); % ESC
    lumIncreaseButton   = KbName('LeftArrow'); % 1
    lumDecreaseButton   = KbName('RightArrow'); % Q
    confirmButton       = KbName('Space'); % Space

    displayWidth        = 800;
    displayHeight       = 600;

        
%     gam_mac = img_gammaLUT(repmat((0:255)',1,3), 2.2);
%     LUT = img_gammaLUT(gam_mac, 1);
end

% check what this is doing
LUT = textread('spc_mrz3t_gammaLUT.txt'); % img_gammaLUT(gamma_mon,1); % lookup table to make monitor linear


xSize = ptb.screenXpixels;
ySize = ptb.screenYpixels;

% Screen('TextStyle', ptb.window ,1); % 1: BOLD

% Enable alpha blending with proper blend-function. We need it
% for drawing of smoothed points:
% Screen('BlendFunction', ptb.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% black = BlackIndex(w);
lum = 1; %255;

% Background colors and initial luminance settings
trueColor.red    = [0.89040261 0.07737457 0.07445575];
trueColor.green  = [0.33625086 0.51528191 0.28597812];
trueColor.orange = [0.90565069 0.39444017 0.11520369];
trueColor.yellow = [0.90866778 0.78573948 0.11242274];

invColor.red    = [0.00866076 0.57562243 0.83034924];
invColor.green  = [0.5571594  0.41451602 0.65644618];
invColor.orange = [0.05491524 0.65910068 0.9429003];
invColor.yellow = [0.12867932 0.81841307 0.98263644];

grey = [ptb.grey ptb.grey ptb.grey];

% Define comparison stimuli
nCompStim = 13;
rangeCompStim = .1; % Raised from .15 to .2 because luminance differences are less noticeable in the scanner

% Note that the lumFactors are assymmetrical because there we're closer to
% the upper bound of possible stimulus luminances given by the maximum
% output of the RGB guns than the lower bounds.
lumFactors = .9-rangeCompStim:(2*rangeCompStim)/(nCompStim-1):.9+rangeCompStim;


% HideCursor;	% Hide the mouse cursor
% Priority(MaxPriority(ptb.window));

% Text settings
% Screen('TextSize', ptb.window, 21);
% Screen('TextFont', ptb.window, 'Helvetica');
% Screen('TextColor', ptb.window, [255 255 0]);

% Prepare instruction screen
instructionStr = sprintf(['COLOR ADJUSTMENT\n\n'...
    'In the following task you will be shown a series of flickering color patches.\n'...
    'The goal of this task is to change the luminance of each patch such that the\n'...
    'flickering is minimized.\n\n'...
    'You are going to increase or decrease the luminance of the patch using the two\n'...
    '''increase/decrease'' buttons. You can make adjustments for as long as you want.\n'...
    'If you think that minimal flickering has been achieved, press the ''accept'' button\n'...
    'This task is repeated for eight different color patches.\n\n'...
    '(PRESS ANY KEY TO PROCEED)']);


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
Screen('Flip', ptb.window);
while 1
    [ ~, ~, keyCode ] = KbCheck;
    if ismember(find(keyCode), [lumIncreaseButton lumDecreaseButton terminateButton])
        break;
    end
end

% Use these variables to read information from in each 'for' iteration
allColors = {...
    trueColor.red, ...
    trueColor.green, ...
    trueColor.orange, ...
    trueColor.yellow, ...
    invColor.red, ...
    invColor.green, ... 
    invColor.orange, ...
    invColor.yellow ...
    };
    
% Randomize sequence
randSeq = randperm(numel(allColors));
allColors = allColors(randSeq);

% Output will be stored in this matrix (Columns 1-3 correspond to R, G, & B)
rgbIsolum = zeros(numel(allColors), 3);
xyYIsolum = rgbIsolum; 

% Iterate over all colors that need to be adjusted
for curCol = 1:numel(allColors)
        
    curDiagColor = allColors{curCol};
    curLumFactor = 1; %randi(nCompStim);
    
    curFrame = 1;
    spaceDown = 0;  % Has P pressed the space bar?
    responseKeyReleased = 1;    % Has P released response key?
    % Color adjustment
    while ~spaceDown
        if curFrame > 1
            % Background
            % Select   left-eye image buffer for drawing:
            Screen('SelectStereoDrawBuffer', ptb.window, 0);
%             Screen('FillRect', ptb.window, img_gammaConvert(LUT,round(lum*curInvColor)));

            if mod(curFrame,2) == 1 % Gray
                Screen('FillRect',ptb.window, img_gammaConvert(LUT,lum*grey), round([ptb.xCenter-.15*xSize  ptb.yCenter-.15*ySize  ptb.xCenter+.15*xSize ptb.yCenter+.15*ySize] ));
            elseif mod(curFrame,2) == 0 % Colored
                Screen('FillRect',ptb.window, img_gammaConvert(LUT,lum*curDiagColor*lumFactors(curLumFactor)), round([ptb.xCenter-.15*xSize  ptb.yCenter-.15*ySize  ptb.xCenter+.15*xSize ptb.yCenter+.15*ySize] ));
            end

            % Show color name and RGB values at the top
            colorStr = sprintf('%1.2f ',img_gammaConvert(LUT,lum*curDiagColor*lumFactors(curLumFactor)));
            Screen('DrawText', ptb.window, ['RGB-values: ' colorStr],   round(ptb.xCenter-.15*xSize),  round(ptb.yCenter-.2*ySize), ptb.white); 

            % Show resulting color at the bottom 
            Screen('FillRect',ptb.window, img_gammaConvert(LUT,round(lum*curDiagColor*lumFactors(curLumFactor))), round([ptb.xCenter-.15*xSize  ptb.yCenter+.175*ySize  ptb.xCenter+.15*xSize ptb.yCenter+.2*ySize]));
            % Select   righ-eye image buffer for drawing:
            Screen('SelectStereoDrawBuffer', ptb.window, 1);
%             Screen('FillRect', ptb.window, img_gammaConvert(LUT,round(lum*curInvColor)));

            if mod(curFrame,2) == 1 % Gray
                Screen('FillRect',ptb.window, img_gammaConvert(LUT,lum*grey), round([ptb.xCenter-.15*xSize  ptb.yCenter-.15*ySize  ptb.xCenter+.15*xSize ptb.yCenter+.15*ySize] ));
            elseif mod(curFrame,2) == 0 % Colored
                Screen('FillRect',ptb.window, img_gammaConvert(LUT,lum*curDiagColor*lumFactors(curLumFactor)), round([ptb.xCenter-.15*xSize  ptb.yCenter-.15*ySize  ptb.xCenter+.15*xSize ptb.yCenter+.15*ySize] ));
            end

            % Show resulting color at the bottom 
            Screen('FillRect',ptb.window, img_gammaConvert(LUT,round(lum*curDiagColor*lumFactors(curLumFactor))), round([ptb.xCenter-.15*xSize  ptb.yCenter+.175*ySize  ptb.xCenter+.15*xSize ptb.yCenter+.2*ySize]));
            Screen('DrawingFinished', ptb.window); % Tell PTB that no further drawing commands will follow before Screen('Flip')
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
                    curLumFactor = curLumFactor+1;
                    if  curLumFactor > nCompStim, curLumFactor = nCompStim; end

                case lumDecreaseButton
                    curLumFactor = curLumFactor-1;
                    if  curLumFactor < 1, curLumFactor = 1; end

                case confirmButton
                    rgbIsolum(curCol, 1:3) = curDiagColor*lumFactors(curLumFactor);   % Save current settings
                    xyYIsolum(curCol, 1:3) = XYZToxyY(SRGBPrimaryToXYZ(curDiagColor'*lumFactors(curLumFactor)))';
                    disp('--------------------------------------------------------------');
                    fprintf('Adjustment made for stimulus %i:\nx\ty\tY\t\tR\tG\tB\n%.2f\t%.2f\t%.2f\t\t%.2f\t%.2f\t%.2f\n', ...
                        curCol, xyYIsolum(curCol,1), xyYIsolum(curCol,2), xyYIsolum(curCol,3), ...
                        rgbIsolum(curCol,1), rgbIsolum(curCol,2), rgbIsolum(curCol,3));
                    while KbCheck; end % Wait until all keys have been released
                    spaceDown = 1;    % P confirmed adjustment
            end % switch
        elseif keyIsDown == 0
            responseKeyReleased = 1;
        end % if keyIsDown
        curFrame = curFrame + 1;
        Screen('Flip',ptb.window);
    end % while 1
end % for curCol = 1:numel(allProtos)
disp('--------------------------------------------------------------');

% Undo randomization for RGB and xyY color coordinates
rgbIsolum(randSeq,:) = rgbIsolum;
xyYIsolum(randSeq,:) = xyYIsolum;

% Output structure
isolum.rgbIsolum = rgbIsolum;
isolum.xyYIsolum = xyYIsolum;
isolum.names = {'redDim' 'greenDim' 'blueDim' 'yellowDim' ...
    'redBrt' 'greenBrt' 'blueBrt' 'yellowBrt'};


Priority(0);
ShowCursor
% Enable keyboard output to Matlab
ListenChar(0);
Screen('CloseAll');

% Show resulting colors
img = zeros(700, 700, 3);

% Gray background
gray = img_gammaConvert(LUT,round(lum*invColor.bkgrd));
img(:,:,1) = gray(1)/255;
img(:,:,2) = gray(2)/255;
img(:,:,3) = gray(3)/255;

rgbIsolumGamCor = img_gammaConvert(LUT, rgbIsolum);

% Add colors
img(101:300, 101:300, 1) = rgbIsolumGamCor(1,1);
img(101:300, 101:300, 2) = rgbIsolumGamCor(1,2);
img(101:300, 101:300, 3) = rgbIsolumGamCor(1,3);

img(101:300, 401:600, 1) = rgbIsolumGamCor(2,1);
img(101:300, 401:600, 2) = rgbIsolumGamCor(2,2);
img(101:300, 401:600, 3) = rgbIsolumGamCor(2,3);

img(401:600, 101:300, 1) = rgbIsolumGamCor(3,1);
img(401:600, 101:300, 2) = rgbIsolumGamCor(3,2);
img(401:600, 101:300, 3) = rgbIsolumGamCor(3,3);

img(401:600, 401:600, 1) = rgbIsolumGamCor(4,1);
img(401:600, 401:600, 2) = rgbIsolumGamCor(4,2);
img(401:600, 401:600, 3) = rgbIsolumGamCor(4,3);

% Show colors
figure;
subplot(1,2,1);
imshow(img);

% Gray background
gray = img_gammaConvert(LUT,round(lum*invColor.bkgrd));
img(:,:,1) = gray(1)/255;
img(:,:,2) = gray(2)/255;
img(:,:,3) = gray(3)/255;

% Add colors
% img(101:300, 101:300, 1) = rgbIsolumGamCor(5,1);
% img(101:300, 101:300, 2) = rgbIsolumGamCor(5,2);
% img(101:300, 101:300, 3) = rgbIsolumGamCor(5,3);
% 
% img(101:300, 401:600, 1) = rgbIsolumGamCor(6,1);
% img(101:300, 401:600, 2) = rgbIsolumGamCor(6,2);
% img(101:300, 401:600, 3) = rgbIsolumGamCor(6,3);
% 
% img(401:600, 101:300, 1) = rgbIsolumGamCor(7,1);
% img(401:600, 101:300, 2) = rgbIsolumGamCor(7,2);
% img(401:600, 101:300, 3) = rgbIsolumGamCor(7,3);
% 
% img(401:600, 401:600, 1) = rgbIsolumGamCor(8,1);
% img(401:600, 401:600, 2) = rgbIsolumGamCor(8,2);
% img(401:600, 401:600, 3) = rgbIsolumGamCor(8,3);

subplot(1,2,2);
imshow(img);

writeShaderFiles = input('Do you want to create the shader files? (0 = false; 1 = true) :');
if writeShaderFiles == 1
%     mkdir('output')
    % Write shader code to file
    for curCol = 1:numel(allColors)
        colorStr = isolum.names{curCol}(1:end-3);
        lumStr = isolum.names{curCol}(end-2:end);
        
        rgbBkgrd = img_gammaConvert(LUT, .5*ones(1,3));

%         if strcmp(lumStr, 'Brt')
%             rgbBkgrd = img_gammaConvert(LUT, matchBrt.bkgrd);
%         elseif strcmp(lumStr, 'Dim')
%             rgbBkgrd = img_gammaConvert(LUT, matchDim.bkgrd);
%         end
        
        subfolder = [colorStr 'Rings' lumStr '/'];
%         mkdir(['output/' subfolder]);

        for curMotDirection = 1:2
            if curMotDirection == 1
                directionStr = 'In';
                shaderAddOrSubtract = '-';
            else
                directionStr = 'Out';
                shaderAddOrSubtract = '+';
            end
            fid = fopen(['../stimuli/equalizedStimuli/' subfolder colorStr 'Rings' lumStr directionStr '.frag.txt'],'w');
            fprintf(fid, ['/* THIS CODE WAS GENERATED AUTOMATICALLY BY FUNCTION isolumSelectionMri.m */\n\n'...
                'uniform vec2 location;\n'...
                'uniform float shaderParam;\n\n'...
                '/*Color definitions*/'...                
                'const vec4 firstColor= vec4(%.2f, %.2f, %.2f, 1.0);\n'...
                'const vec4 secondColor = vec4(%.2f, %.2f, %.2f, 1.0);\n\n'...
                '/*Stimulus size definition\n'...
                'Actual screen resolution currently is %i by %i\n'...
                'Cycles per degree (assuming a resolution of 800 by 600): 0.5 (eg., Brouwer & Heeger)\n'... 
                'Screen size in visual degrees at 3T MRZ is: 21.54? by 15.96?*/\n'... 
                'const float cycleSizePix = 74.2804;\n'...
                '/*Circle radius in visual degrees (assuming a resolution of 800 by 600): 7.189*/\n'...
                'const float radiusPix = 267.0;\n'...
                'const float twopi = 2.0 * 3.141592654;\n\n'...
                'void main()\n'...
                '{\n'...
                '\t/* Query current output texel position: */\n'...
                '\tvec2 pos = gl_TexCoord[0].xy;\n\n'...
                '\t/* Compute euclidean distance to center of our ring stim: */\n'...
                '\tfloat d = distance(pos, location);\n\n'...
                '\t/* If distance greater than maximum radius, discard this pixel: */\n'...
                '\tif (d > radiusPix) discard;\n\n'...
                '\t/* Convert distance from units of pixels into units of ringwidths, apply shift offset: */\n'...
                '\t/* pi doesn''t seem to be available as a constant in GLSL - I therefore used 2.0 * asin(1.0) instead */\n'...
                '\td = (1.0 + sin((d ' shaderAddOrSubtract ' shaderParam) / cycleSizePix * twopi)) * 0.5;\n\n'...
                '\t/* A pixel in an even-numbered ring is drawn in gl_Color, the color assigned in the\n'...
                '\tScreen(''DrawTexture'') command as modulateColor, whereas a pixel in an odd-numbered\n'...
                '\tring is assigned ''secondColor'': */\n'...
                '\tgl_FragColor = mix(firstColor, secondColor, d);\n'...
                '}'], rgbIsolumGamCor(curCol,1), rgbIsolumGamCor(curCol,2), rgbIsolumGamCor(curCol,3), ...
                rgbBkgrd(1), rgbBkgrd(2), rgbBkgrd(3), xSize, ySize);
            fclose(fid);
        end        
    end
    save('../stimuli/equalizedStimuli/isolum.mat','isolum');
end
