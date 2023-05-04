function savedata(log,ptb,design)
    %.............................GET RESPONSES...........................%
    % Regardless of HOW the experiment ended.
    % Stop KbQueue data collection
    KbQueueStop(ptb.Keyboard2); 
    KbQueueStop(ptb.Keyboard1);     
    
    % Extract events
    while KbEventAvail(ptb.Keyboard2)
        [evt, ~] = KbEventGet(ptb.Keyboard2);
        
        if evt.Pressed == 1
            log.data.idDown   = [log.data.idDown; evt.Keycode];
            log.data.timeDown = [log.data.timeDown; evt.Time];
        else
            log.data.idUp   = [log.data.idUp; evt.Keycode];
            log.data.timeUp = [log.data.timeUp; evt.Time];
        end
    end
    
    if strcmp(log.end,'Finished with errors')
        save(fullfile(log.subjectDir, [log.sub '_ptb_error']),'ptb');
        save(fullfile(log.subjectDir, [log.sub '_log_error']),'log');
        save(fullfile(log.subjectDir, [log.sub '_design_error']),'design');
        if design.useET; unixStr=['mv ' log.edfFile ' ' [log.edfFile] '_error.edf'];unix(unixStr);end
    elseif strcmp(log.end,'Escape')
        save(fullfile(log.subjectDir, [log.sub '_ptb_cancelled']),'ptb');
        save(fullfile(log.subjectDir, [log.sub '_log_cancelled']),'log'); fprintf('\n Saved cancelled data.... \n');
        save(fullfile(log.subjectDir, [log.sub '_design_cancelled']),'design');
        if design.useET; unixStr=['mv ' log.edfFile ' ' [log.edfFile] '_cancelled.edf'];unix(unixStr);end
    elseif strcmp(log.end,'Success')
        save(fullfile(log.subjectDir, [log.sub '_ptb']),'ptb');
        save(fullfile(log.subjectDir, [log.sub '_log']),'log'); fprintf('\n Saved success data.... \n');
        save(fullfile(log.subjectDir, [log.sub '_design']),'design');
    end 
        
end