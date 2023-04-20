# BR and memory color

Project for a Binocular Rivalry (BR) experiment using images of objects associated with a color

## Stimuli
Stimuli are taken from the experiment of Teichmann et al., 2020. which are freely available [here] (https://osf.io/tcqjh/).<br>
For the experiment the background of stimuli was made transparent by adding an alpha channel to the images and setting its value to 0 for all pixels that are white (original background)<br>
**TO-DO**: Change this procedure to a more precise one. At the current stage some pixels in some stimuli are white, but do not belong to the background.<br>

Stimulus color was inverted by converting the image from BGR space (*not* RGB because I use open cv) to HLS space and increased the hue channel value by 90.

## Experiment
Experimental code will be derived from previous code proveded by Dr. Pablo Grassi
