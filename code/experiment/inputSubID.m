function [sub, subjectDir, language] = inputSubID(dataDir, ptb)
    % Gets input of experimentator for subject ID
    % Get input and check if it is a number or 'test'
    numSubjects = 5;
    checkinput = true;
    safetynet = true;
    % TODO: make the language dependent on input in second while loop
    
    try
        while safetynet
            %% GET SUBJECT DATA
            subjectNr = input('Enter subject Nr: ','s');
            while checkinput
                if (str2double(subjectNr)<=numSubjects || strcmp (subjectNr, 'test'))
                    checkinput = false;
                else
                    disp ('Invalid input. Make it right')
                    subjectNr = input('Enter subject Nr: ','s');
                end
            end
            checkinput = true;
            while checkinput
                isGerman = input ('Does the subject understand german [y/n]? ','s');
                if strcmp (isGerman, KbName(ptb.Keys.yes))
                    language = 'german';
                    checkinput = false;
                elseif strcmp (isGerman, KbName(ptb.Keys.no))
                    language = 'english';
                    checkinput = false;
                else
                    fprintf('Please answer with "y" or "n".\n')
                end
            end
            
            fprintf (['You specified subj ' subjectNr '\n'])
            answer = input ('Are you sure you gave the right parameters?','s');
            if strcmp (answer, 'y')
                safetynet = false;
            end
            checkinput = true;
        end

        % call create subjectDir
        [sub, subjectDir] = createSubDir(dataDir, subjectNr);

    catch INPUT_ERROR
        rethrow (INPUT_ERROR);
    end
end