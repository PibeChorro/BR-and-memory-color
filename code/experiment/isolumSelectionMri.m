function isolumSelectionMri(sub)
% get equiluminant colors using the flicker method
% The function reads in a table with RGB values of diagnostic colors for a
% set of stimlui and the corresonding RGB values of the inverted color in
% CIELab* space.
% Each color is presented with its inversion and luminance can be adjusted
% until the colored rectangles do not flicker anymore (i.e., they are
% equiluminant
% The resulting table is then saved in the subject directory

if nargin < 1
    sub = 'sub-test';
end
if isnumeric(sub)
    sub = sprintf('sub-%02d',sub);
end
% get all the important setting information
PsychDefaultSetup(2);
ptb = PTBSettings();

KbName('UnifyKeyNames');
% Define response buttons
terminateButton     = KbName('ESCAPE'); % ESC
lumIncreaseButton   = KbName('LeftArrow'); % 1
lumDecreaseButton   = KbName('RightArrow'); % Q
confirmButton       = KbName('Space'); % Space

% read in setup specific gamma correction table
switch ptb.SetUp
    case 'CIN-personal'
        LUT = readmatrix('gammaLUT.txt'); % lookup table to make monitor linear
    case 'CIN-experimentroom'
        LUT = textread('spc_mrz3t_gammaLUT.txt'); % img_gammaLUT(gamma_mon,1); % lookup table to make monitor linear
    case 'MPI'
        LUT = textread('spc_mrz3t_gammaLUT.txt'); % img_gammaLUT(gamma_mon,1); % lookup table to make monitor linear
    otherwise
        error('No valid setup choise')
end

% Read in table with typical RGB values for each stimulus
colorTableDir = fullfile('..','..','stimuli','representative_pixels.csv');
colorTable = readtable(colorTableDir, 'TextType','string');
numColors = size(colorTable,1);
% shuffle table 
randSeq = randperm(numColors);
colorTable = colorTable(randSeq,:);

% create copy of color table to store the adjusted RGB - values in
equilumColorTable = colorTable;

% create subject directory to store the resulting table in
subjectDirectory = fullfile('..','..','rawdata',sub);
outputDir = fullfile(subjectDirectory,'equiluminantColorTable.csv');
if (~isfolder(subjectDirectory))
    mkdir(subjectDirectory);
end

% stepsize with which the luminance should be increased/decreased
stepSize = 0.05;

xSize = ptb.screenXpixels;
ySize = ptb.screenYpixels;

% rectangle where color is shown
rectCoordinates = round([...
    ptb.xCenter-.15*xSize ...
    ptb.yCenter-.15*ySize ...
    ptb.xCenter+.15*xSize ...
    ptb.yCenter+.15*ySize]);

lum = 255;
grey = [ptb.grey ptb.grey ptb.grey];

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

% Output will be stored in this matrix (Columns 1-3 correspond to R, G, & B)
xyYIsolum = zeros(size(colorTable,1));

% Iterate over all colors that need to be adjusted
for curCol = 1:numColors
    % Get current true color values
    curTrueR = colorTable.true_R(curCol);
    curTrueG = colorTable.true_G(curCol);
    curTrueB = colorTable.true_B(curCol);
    curTrueColor = [curTrueR curTrueG curTrueB];
    
    % Get current inverted color values
    curFalseR = colorTable.inv_R(curCol);
    curFalseG = colorTable.inv_G(curCol);
    curFalseB = colorTable.inv_B(curCol);
    curFalseColor = [curFalseR curFalseG curFalseB];

    curTrueLumFactor = 1; 
    curFalseLumFactor = 1;
    maxCurTrueLumFactor = 255/max(curTrueColor);
    maxCurFalseLumFactor = 255/max(curFalseColor);
    
    curFrame = 1;
    spaceDown = 0;  % Has P pressed the space bar?
    responseKeyReleased = 1;    % Has P released response key?
    % Color adjustment
    while ~spaceDown
        if curFrame > 1
            % Select   left-eye image buffer for drawing:
            Screen('SelectStereoDrawBuffer', ptb.window, 0);
            if mod(curFrame,2) == 1 % Inversed color
                Screen('FillRect',ptb.window, img_gammaConvert(LUT,round(curFalseColor*curFalseLumFactor)/lum), rectCoordinates);
            elseif mod(curFrame,2) == 0 % True color
                Screen('FillRect',ptb.window, img_gammaConvert(LUT,round(curTrueColor*curTrueLumFactor)/lum), rectCoordinates);
            end

            % Select   right-eye image buffer for drawing:
            Screen('SelectStereoDrawBuffer', ptb.window, 1);
            if mod(curFrame,2) == 1 % Inversed color
                Screen('FillRect',ptb.window, img_gammaConvert(LUT,round(curFalseColor*curFalseLumFactor)/lum), rectCoordinates);
            elseif mod(curFrame,2) == 0 % True color
                Screen('FillRect',ptb.window, img_gammaConvert(LUT,round(curTrueColor*curTrueLumFactor)/lum), rectCoordinates);
            end

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
                    curTrueLumFactor = curTrueLumFactor+stepSize;
                    curFalseLumFactor = curFalseLumFactor-stepSize;

                case lumDecreaseButton
                    curTrueLumFactor = curTrueLumFactor-stepSize;
                    curFalseLumFactor = curFalseLumFactor+stepSize;

                case confirmButton
                    % Save current settings
                    xyYIsolum(curCol, 1:3) = XYZToxyY(SRGBPrimaryToXYZ(curTrueColor'*curTrueLumFactor))';
                    disp('--------------------------------------------------------------');
                    fprintf('Adjustment made for stimulus %i:\nx\ty\tY\t\tR\tG\tB\n%.2f\t%.2f\t%.2f\t\t%.2f\t%.2f\t%.2f\n', ...
                        curCol, xyYIsolum(curCol,1), xyYIsolum(curCol,2), xyYIsolum(curCol,3), ...
                        trueRgbIsolum(curCol,1), trueRgbIsolum(curCol,2), trueRgbIsolum(curCol,3));
                    % save new color values in table
                    equilumColorTable.true_R(curCol) = curTrueColor(1)*curTrueLumFactor;
                    equilumColorTable.true_G(curCol) = curTrueColor(2)*curTrueLumFactor;
                    equilumColorTable.true_B(curCol) = curTrueColor(3)*curTrueLumFactor;

                    equilumColorTable.inv_R(curCol) = curFalseColor(1)*curFalseLumFactor;
                    equilumColorTable.inv_G(curCol) = curFalseColor(2)*curFalseLumFactor;
                    equilumColorTable.inv_B(curCol) = curFalseColor(3)*curFalseLumFactor;

                    while KbCheck; end % Wait until all keys have been released
                    spaceDown = 1;    % P confirmed adjustment
            end % switch

            % Make sure the luminance factor does not exceed boundaries
            if curTrueLumFactor > maxCurTrueLumFactor 
                curTrueLumFactor = maxCurTrueLumFactor; 
            end
            if  curFalseLumFactor > maxCurFalseLumFactor 
                curFalseLumFactor = maxCurFalseLumFactor; 
            end
            if curTrueLumFactor <= 0
                curFalseLumFactor = 0;
            end
            if curFalseLumFactor <= 0
                curFalseLumFactor = 0;
            end
        elseif keyIsDown == 0
            responseKeyReleased = 1;
        end % if keyIsDown
        curFrame = curFrame + 1;
        Screen('Flip',ptb.window);
    end % while 1
end % for curCol = 1:numel(allProtos)
disp('--------------------------------------------------------------');

% Undo randomization for color tables
colorTable(randSeq,:) = colorTable;
equilumColorTable(randSeq,:) = equilumColorTable;
% save equiluminant color table
writetable(equilumColorTable, outputDir)

xyYIsolum(randSeq,:) = xyYIsolum;

Priority(0);
ShowCursor
% Enable keyboard output to Matlab
ListenChar(0);
Screen('CloseAll');

% Show resulting colors
img = zeros(700, 1000, 3);

% Gray background
gray = img_gammaConvert(LUT,round(lum*grey));
img(:,:,1) = gray(1)/255;
img(:,:,2) = gray(2)/255;
img(:,:,3) = gray(3)/255;

blueIdx     = find(colorTable.stimuli=='blue_nivea.png');
redIdx      = find(colorTable.stimuli=='red_tomato.png');
rangeIdx    = find(colorTable.stimuli=='orange_pumpkin.png');
yellowIdx   = find(colorTable.stimuli=='yellow_banana.png');
greenIdx    = find(colorTable.stimuli=='green_brokkoli_1.png');

% Add colors
img(101:300, 101:300, 1) = colorTable.true_R(blueIdx)/lum;
img(101:300, 101:300, 2) = colorTable.true_G(blueIdx)/lum;
img(101:300, 101:300, 3) = colorTable.true_B(blueIdx)/lum;

img(101:300, 401:600, 1) = colorTable.true_R(redIdx)/lum;
img(101:300, 401:600, 2) = colorTable.true_G(redIdx)/lum;
img(101:300, 401:600, 3) = colorTable.true_B(redIdx)/lum;

img(401:600, 101:300, 1) = colorTable.true_R(rangeIdx)/lum;
img(401:600, 101:300, 2) = colorTable.true_G(rangeIdx)/lum;
img(401:600, 101:300, 3) = colorTable.true_B(rangeIdx)/lum;

img(401:600, 401:600, 1) = colorTable.true_R(yellowIdx)/lum;
img(401:600, 401:600, 2) = colorTable.true_G(yellowIdx)/lum;
img(401:600, 401:600, 3) = colorTable.true_B(yellowIdx)/lum;

img(251:550, 701:900, 1) = colorTable.true_R(greenIdx)/lum;
img(251:550, 701:900, 2) = colorTable.true_G(greenIdx)/lum;
img(251:550, 701:900, 3) = colorTable.true_B(greenIdx)/lum;

% Show colors
figure;
subplot(1,2,1);
imshow(img);

% Gray background
gray = img_gammaConvert(LUT,round(lum*grey));
img(:,:,1) = gray(1)/255;
img(:,:,2) = gray(2)/255;
img(:,:,3) = gray(3)/255;

blueIdx     = find(colorTable.stimuli=='blue_nivea.png');
redIdx      = find(colorTable.stimuli=='red_tomato.png');
rangeIdx   = find(colorTable.stimuli=='orange_pumpkin.png');
yellowIdx   = find(colorTable.stimuli=='yellow_banana.png');
greenIdx    = find(colorTable.stimuli=='green_brokkoli_1.png');

% Add colors
img(101:300, 101:300, 1) = colorTable.inv_R(blueIdx)/lum;
img(101:300, 101:300, 2) = colorTable.inv_G(blueIdx)/lum;
img(101:300, 101:300, 3) = colorTable.inv_B(blueIdx)/lum;

img(101:300, 401:600, 1) = colorTable.inv_R(redIdx)/lum;
img(101:300, 401:600, 2) = colorTable.inv_G(redIdx)/lum;
img(101:300, 401:600, 3) = colorTable.inv_B(redIdx)/lum;

img(401:600, 101:300, 1) = colorTable.inv_R(rangeIdx)/lum;
img(401:600, 101:300, 2) = colorTable.inv_G(rangeIdx)/lum;
img(401:600, 101:300, 3) = colorTable.inv_B(rangeIdx)/lum;

img(401:600, 401:600, 1) = colorTable.inv_R(yellowIdx)/lum;
img(401:600, 401:600, 2) = colorTable.inv_G(yellowIdx)/lum;
img(401:600, 401:600, 3) = colorTable.inv_B(yellowIdx)/lum;

img(251:550, 701:900, 1) = colorTable.inv_R(greenIdx)/lum;
img(251:550, 701:900, 2) = colorTable.inv_G(greenIdx)/lum;
img(251:550, 701:900, 3) = colorTable.inv_B(greenIdx)/lum;


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
                '}'], trueRgbIsolumGamCor(curCol,1), trueRgbIsolumGamCor(curCol,2), trueRgbIsolumGamCor(curCol,3), ...
                rgbBkgrd(1), rgbBkgrd(2), rgbBkgrd(3), xSize, ySize);
            fclose(fid);
        end        
    end
    save('../stimuli/equalizedStimuli/isolum.mat','isolum');
end
