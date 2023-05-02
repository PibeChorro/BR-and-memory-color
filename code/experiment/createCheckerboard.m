function checkerBoard = createCheckerboard(xSize, ySize, xFrequency,yFrequency)
% create a checkerboard 
% xSize, ySize - the size of the checkerboard in pixels
% xFrequency, yFrequency - how often we have white and black 

% calculate how many pixels one rectangle has along the axes
xPixels = xSize/xFrequency/2;
yPixels = ySize/yFrequency/2;

% create a white and black rectangle
white = ones(xPixels, yPixels)*0.8;
black = zeros(xPixels, yPixels);

% create a small checkerboard with only four parts
smallCheckerboard = [black white; white black];

% create the big checkerboard
checkerBoard = repmat(smallCheckerboard,xFrequency,yFrequency);
end