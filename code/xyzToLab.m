% Convert images from xyz space into lab space

%% Get the input and output directories

xyzInputDir = fullfile('..','stimuli','xyz_color');
labOutputDir = fullfile('..','stimuli','lab_color');

if ~isfolder(labOutputDir)
    mkdir(labOutputDir)
end

%% Get all stimuli in the inut folder

allImages = dir(fullfile(xyzInputDir, '*.png'));
% iterate over all images, transform them into lab space and save in the
% output dir
maxValue = 255;

for idx = 1:length(allImages)
    disp('Read in image:')
    disp(allImages(idx).name)
    img = imread(fullfile(xyzInputDir,allImages(idx).name));
    dimg = double(img);
    lab = xyz2lab(dimg);
    lab(lab>maxValue) = maxValue;
    uinLab = uint8(lab);
    imwrite(uinLab,fullfile(labOutputDir,allImages(idx).name),"png");
end