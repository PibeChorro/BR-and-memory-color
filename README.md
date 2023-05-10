# BR and memory color

Project for a Binocular Rivalry (BR) experiment using images of objects associated with a color

## Stimuli
Stimuli are taken from the experiment of Teichmann et al., 2020. which are freely available [here] (https://osf.io/tcqjh/).<br>
For the experiment the background of stimuli was made transparent by adding an alpha channel to the images and setting its value to 0 for all pixels that are white (original background)<br>
**NOTE**: In some of the stimuli some foreground pixels (i.e., pixels belonging to the object) were deleted because they were white.<br>

*Images with white pixels added*<br>
- orange_pumpkins<br>
- orange_pumpkin<br>
- red_cherries<br>
- red_cherry<br>
- red_fire_extinguisher_2<br>
- red_ladybug_1<br>
- red_strawberries<br>
- red_strawberry<br>

Adding single pixels was done in GIMP 2.10.30 on a Ubuntu 22.04 system running KDE.<br>
The images before manipulation are moved to the `gimp` folder under `stimuli`.

Stimulus color was converted into three different color spaces:<br>
1. HSL<br>
2. LUV<br>
3. LAB<br>

For 1. color was inverted by adding 90 to the hue channel, for 2. and 3. color was inverted by subtracting 255 from the uv and ab channels respectively

## Experiment
Experimental code will be derived from previous code proveded by Dr. Pablo Grassi
