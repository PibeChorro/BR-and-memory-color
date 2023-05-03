# BR and memory color

Project for a Binocular Rivalry (BR) experiment using images of objects associated with a color

## Stimuli
Stimuli are taken from the experiment of Teichmann et al., 2020. which are freely available [here] (https://osf.io/tcqjh/).<br>
For the experiment the background of stimuli was made transparent by adding an alpha channel to the images and setting its value to 0 for all pixels that are white (original background)<br>
**NOTE**: In some of the stimuli some foreground pixels (i.e., pixels belonging to the object) were deleted because they were white.<br>

*Images with white pixels added*
- orange_pumpkins
- orange_pumpkin
- red_cherries
- red_cherry
- red_strawberries
- red_strawberry

Adding single pixels was done in GIMP 2.10.30 on a Ubuntu 22.04 system running KDE.<br>
The images before manipulation are moved to the `gimp` folder under `stimuli`.


Stimulus color was inverted by converting the image from BGR space (*not* RGB because I use open cv) to HLS space and increased the hue channel value by 90.

## Experiment
Experimental code will be derived from previous code proveded by Dr. Pablo Grassi
