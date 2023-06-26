#!/usr/bin/env python
# coding: utf-8

# In[1]:


# use the os
import os
import glob
# math and data structure
import numpy as np
import pandas as pd
# plotting
import matplotlib.pyplot as plt
# image processing
import cv2


# In[2]:


stim_dir = os.path.join('..','stimuli')
data_dir = os.path.join('..','rawdata')

# taken from original - added alpha channel
true_color_stim_dir = os.path.join(stim_dir,'true_color')
# stimuli in LAB space inverted
inverted_lab_stim_dir = os.path.join(stim_dir,'inverted_lab')
# mask to apply the change
mask_dir = os.path.join(stim_dir,'color_masks')
# forground_background masks to apply the alpha channel
fb_mask_dir = os.path.join(stim_dir, 'foreground_background_masks')

# subject directory
sub_dir = os.path.join(data_dir,'sub-test')
# stimulus folder for subject to store subject specific equiluminant images
sub_stim_dir = os.path.join(sub_dir,'stimuli')
if not os.path.exists(sub_stim_dir):
    os.mkdir(sub_stim_dir)
sub_true_stim_dir = os.path.join(sub_stim_dir, 'true_color')
if not os.path.exists(sub_true_stim_dir):
    os.mkdir(sub_true_stim_dir)
sub_inv_stim_dir = os.path.join(sub_stim_dir, 'inverted_color')
if not os.path.exists(sub_inv_stim_dir):
    os.mkdir(sub_inv_stim_dir)

# directory where to store images where pixels were clipped
clipped_stimuli_dir = os.path.join(sub_dir,'clipped_stimuli')
if not os.path.exists(clipped_stimuli_dir):
    os.mkdir(clipped_stimuli_dir)
true_clipped_dir = os.path.join(clipped_stimuli_dir,'true_color')
if not os.path.exists(true_clipped_dir):
    os.mkdir(true_clipped_dir)
inv_clipped_dir = os.path.join(clipped_stimuli_dir,'inverted_color')
if not os.path.exists(inv_clipped_dir):
    os.mkdir(inv_clipped_dir)


# In[3]:


# get a list of all stimuli in the directory
stimuli_full_path = glob.glob(os.path.join(true_color_stim_dir,'*.png'))
stimuli_full_path.sort()

# extract the image name from the stimulus path
stimuli = [os.path.basename(stim) for stim in stimuli_full_path]


# In[4]:


# read in the table containing the typical color values for all 
color_table = pd.read_csv(os.path.join(stim_dir,'representative_pixels.csv'))
# read in the subject specific luminance correction table
equilum_table = pd.read_csv(os.path.join(sub_dir,'equiluminantColorTable.csv'))


# In[5]:


# iterate over entries in the equiluminance table
# read in the original (true and inverted color) stimuli, 
# normalize it to the "typical pixel" and 
# multiply with the luminance correction factor
for (_,color_item), (_, lum_item) in zip(color_table.iterrows(), equilum_table.iterrows()): 
    # get stimuli paths
    cur_true_path = os.path.join(true_color_stim_dir, lum_item.stimuli)
    cur_inv_path = os.path.join(inverted_lab_stim_dir, lum_item.stimuli)
    # get mask paths
    cur_mask_path = os.path.join(mask_dir, lum_item.stimuli)
    cur_fb_mask_path = os.path.join(fb_mask_dir, lum_item.stimuli)
    
    cur_true_img = cv2.imread(cur_true_path)
    cur_inv_img = cv2.imread(cur_inv_path)
    cur_mask_img = cv2.imread(cur_mask_path)
    cur_fb_mask_img = cv2.imread(cur_fb_mask_path)
    # convert the images into float so that you can change them better and they are not ceiled
    cur_true_img = cur_true_img.astype(np.float32)
    cur_inv_img = cur_inv_img.astype(np.float32)
    # convert BGR images to RGBA for clarity and to later make 
    cur_true_img = cv2.cvtColor(cur_true_img, cv2.COLOR_BGR2RGBA)
    cur_inv_img = cv2.cvtColor(cur_inv_img, cv2.COLOR_BGR2RGBA)
    # masks also have three channels with either 0 or 255 - make it a two dimensional bool mask
    cur_mask_img = cur_mask_img[:,:,0].astype(bool)
    cur_fb_mask_img = cur_fb_mask_img[:,:,0].astype(bool)
    # get channels of images
    true_r, true_g, true_b, true_a = cv2.split(cur_true_img)
    inv_r, inv_g, inv_b, inv_a = cv2.split(cur_inv_img)
    
    # devide the color channels by their typical color value and multiply with the equiluminant factor
    true_r[cur_mask_img] = true_r[cur_mask_img]/color_item.true_R * lum_item.true_R
    true_g[cur_mask_img] = true_g[cur_mask_img]/color_item.true_G * lum_item.true_G
    true_b[cur_mask_img] = true_b[cur_mask_img]/color_item.true_B * lum_item.true_B
    
    inv_r[cur_mask_img] = inv_r[cur_mask_img]/color_item.inv_R * lum_item.inv_R
    inv_g[cur_mask_img] = inv_g[cur_mask_img]/color_item.inv_G * lum_item.inv_G
    inv_b[cur_mask_img] = inv_b[cur_mask_img]/color_item.inv_B * lum_item.inv_B
    
    # add alpha channel
    true_a[cur_fb_mask_img] = 255
    inv_a[cur_fb_mask_img] = 255
    
    # combine the channels to the corrected images (CAUTION! the correct order for opencv is BGR)
    corr_true_img = cv2.merge((true_b, true_g,true_r, true_a))
    corr_inv_img = cv2.merge((inv_b, inv_g,inv_r, inv_a))
    
    # get all pixels that are larger than 255 and save them to know how many and which pixels were capped
    capped_true_img = corr_true_img.copy()
    capped_true_img -= 255
    capped_true_img[capped_true_img<0] = 0
    
    capped_inv_img = corr_inv_img.copy()
    capped_inv_img -= 255
    capped_inv_img[capped_inv_img<0] = 0
    
    capped_true_img = capped_true_img.astype(np.uint8)
    capped_inv_img = capped_inv_img.astype(np.uint8)
    
    cv2.imwrite(os.path.join(true_clipped_dir,lum_item.stimuli), capped_true_img)
    cv2.imwrite(os.path.join(inv_clipped_dir,lum_item.stimuli), capped_inv_img)
    # ceil the images that they are not larger than 255
    corr_true_img[corr_true_img>255] = 255
    corr_inv_img[corr_inv_img>255] = 255
    
    # convert back into unsigned int
    corr_true_img = corr_true_img.astype(np.uint8)
    corr_inv_img = corr_inv_img.astype(np.uint8)
    
    # write image into subject stimuli folder
    cv2.imwrite(os.path.join(sub_true_stim_dir,lum_item.stimuli),corr_true_img)
    cv2.imwrite(os.path.join(sub_inv_stim_dir,lum_item.stimuli),corr_inv_img)

