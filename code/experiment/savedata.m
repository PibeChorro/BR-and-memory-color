function savedata(log,ptb)
    %.............................GET RESPONSES...........................%
    % Regardless of HOW the experiment ended.
    % Stop KbQueue data collection
    KbQueueStop(ptb.Keys.kbrd2); 
    KbQueueStop(ptb.Keys.kbrd1);     
    
    % Extract events
    while KbEventAvail(ptb.Keys.kbrd2)
        [evt, ~] = KbEventGet(ptb.Keys.kbrd2);
        
        if evt.Pressed == 1
            log.data.idDown   = [log.data.idDown; evt.Keycode];
            log.data.timeDown = [log.data.timeDown; evt.Time];
        else
            log.data.idUp   = [log.data.idUp; evt.Keycode];
            log.data.timeUp = [log.data.timeUp; evt.Time];
        end
    end
    
    if strcmp(log.end,'Finished with errors')
        save([log.fileName '_ptb_error'],'ptb');
        save([log.fileName '_log_error'],'log');
        if ptb.useET; unixStr=['mv ' log.edfFile ' ' [log.edfFile] '_error.edf'];unix(unixStr);end
    elseif strcmp(log.end,'Escape')
        save([log.fileName '_ptb_cancelled'],'ptb');
        save([log.fileName '_log_cancelled'],'log'); fprintf('\n Saved cancelled data.... \n');
        if ptb.useET; unixStr=['mv ' log.edfFile ' ' [log.edfFile] '_cancelled.edf'];unix(unixStr);end
    elseif strcmp(log.end,'Success')
        save([log.fileName '_ptb'],'ptb');
        save([log.fileName '_log'],'log'); fprintf('\n Saved success data.... \n');
    end 
        
end