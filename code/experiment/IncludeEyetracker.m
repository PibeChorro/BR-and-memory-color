function [ET] = IncludeEyetracker(sub)

%% Include the Eyetracker
% To avoid running in to troubles because of the Snd() function that
% Eyelink uses per default, we can do two things:
% 1) Create the following empty text file: "Snd_use_oldstyle.txt".
%    For more information: please read the help of Snd().
%    This file will be deleted in the cleanup function.
% 2) Or tell EyeLink not to send any auditory feedback. (not implemented
%    now)
% The problem is that the beeper() of Eyelink blocks the sound card because
% it calls PsychPortAudio(). This blocks the video presentation because
% Gstreamer cannot access the sound card. (see Email from Mario Kleiner)
% fopen( [PsychtoolboxConfigDir 'Snd_use_oldstyle.txt'], 'wb' );

% Provide Eyelink with details about the graphics environment
% and perform some initializations. The information is returned
% in a structure that also contains useful defaults
% and control codes (e.g. tracker state bit and Eyelink key values).
dummymode=0;       % set to 1 to initialize in dummymode
ET=EyelinkInitDefaults(ptb.window);

% Change some values: make background black and everything else white
% Please check function EyelinkInitDefaults() for more possible
% modifications.
ET.backgroundcolour = BlackIndex(ptb.window); 
ET.foregroundcolour = WhiteIndex(ptb.window);
ET.msgfontcolour    = WhiteIndex(ptb.window);
ET.imgtitlecolour   = WhiteIndex(ptb.window); 
ET.calibrationtargetcolour =[1 1 1];

% Update the values with our modifications
EyelinkUpdateDefaults(ET); 

% allows listening to keyboard. Change later to value 2 to suppress
% keypresses to Matlab window
ListenChar(1);

% Initialization of the connection with the Eyelink Gazetracker.
% exit program if this fails.
if ~EyelinkInit(dummymode, 1)
    fprintf('Eyelink Init aborted.\n');
    cleanup;  % cleanup function
    return;
end

[~, vs]=Eyelink('GetTrackerVersion');
fprintf('Running experiment on a ''%s'' tracker.\n', vs );

Eyelink('command', 'file_event_filter = LEFT, RIGHT, FIXATION, SACCADE, BLINK, MESSAGE');
Eyelink('command', 'file_sample_data = LEFT,RIGHT,GAZE,AREA');

%set link data (used for gaze cursor)
Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
% make sure that we get gaze data from the Eyelink
Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');

edfFile = [sub '.edf'];
% open file to write data to
Eyelink('Openfile', edfFile);

end