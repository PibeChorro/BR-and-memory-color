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

### Blue stimuli
Blue stimuli were added to the set<br>
- blue_nivea (https://images-us.nivea.com/-/media/miscellaneous/media-center-items/5/8/d/5b4b9b1e77eb4f44ad96cf4345bc5e12-original.png)<br>

- blue_swimming_pool (https://www.google.com/search?q=swimming+pool+free+png&tbm=isch&ved=2ahUKEwjxo82F9fn-AhUDmicCHZ3GBkoQ2-cCegQIABAA&oq=swimming+pool+free+png&gs_lcp=CgNpbWcQAzoHCAAQigUQQzoFCAAQgAQ6BggAEAcQHjoICAAQCBAHEB5Q5_wIWMuBCWC0gwloAHAAeACAATSIAbcCkgEBN5gBAKABAaoBC2d3cy13aXotaW1nwAEB&sclient=img&ei=GoFjZPGuEYO0nsEPnY2b0AQ&bih=1055&biw=1920&client=firefox-b-d&hl=en-US#imgrc=xDwdTRmxXdWcFM)<br>

- blue_sign (https://www.google.com/search?q=blaues+schild&tbm=isch&ved=2ahUKEwj6h9_a7_n-AhWTnCcCHZU5A5AQ2-cCegQIABAA&oq=blaues+schild&gs_lcp=CgNpbWcQAzIFCAAQgAQyBAgAEB4yBAgAEB4yBAgAEB4yBAgAEB4yBAgAEB4yBAgAEB4yBAgAEB4yBAgAEB4yBAgAEB46BggAEAgQHlDGCliWFWCnFmgAcAB4AIABPIgBkQWSAQIxNJgBAKABAaoBC2d3cy13aXotaW1nwAEB&sclient=img&ei=gntjZPq-DZO5nsEPlfOMgAk&bih=1055&biw=1920&client=firefox-b-d#imgrc=jwZj4mRrcE35wM)

## Experiment
Experimental code will be derived from previous code proveded by Dr. Pablo Grassi
