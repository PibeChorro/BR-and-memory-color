function log = inputSubID(ptb, log)
    % Gets input of experimentator for subject ID
    % Get input and check if it is a number or 'test'
    numSubjects = 50;
    checkinput = true;
    safetynet = true;
    % TODO: make the language dependent on input in second while loop
    
    try
        while safetynet
            %% GET SUBJECT DATA
            while checkinput
                log.subjectNr = input('Enter subject Nr: ','s');
                if (str2double(log.subjectNr)<=numSubjects || strcmp (log.subjectNr, 'test'))
                    checkinput = false;
                else
                    disp ('Invalid input. Make it right')
                end
            end
            
            checkinput = true;
            while checkinput
                log.isGerman = input('Does the subject understand german [y/n]? ','s');
                if strcmp (log.isGerman, KbName(ptb.Keys.yes))
                    log.language = 'german';
                    checkinput = false;
                elseif strcmp (log.isGerman, KbName(ptb.Keys.no))
                    log.language = 'english';
                    checkinput = false;
                else
                    fprintf('Please answer with "y" or "n".\n')
                end
            end
            
            checkinput = true;
            while checkinput
                log.handedness = input('Subjects handedness [l/r]? ','s');
                if strcmp (log.handedness, 'l')
                    log.handedness = 'left';
                    checkinput = false;
                elseif strcmp (log.handedness, 'r')
                    log.handedness = 'rigth';
                    checkinput = false;
                else
                    fprintf('Please answer with "l" or "r".\n')
                end
            end
            
            checkinput = true;
            while checkinput
                log.dominantEye = input('Subjects dominant eye [l/r]? ','s');
                if strcmp (log.dominantEye, 'l')
                    log.dominantEye = 'left';
                    checkinput = false;
                elseif strcmp (log.dominantEye, 'r')
                    log.dominantEye = 'rigth';
                    checkinput = false;
                else
                    fprintf('Please answer with "l" or "r".\n')
                end
            end
            
            checkinput = true;
            while checkinput
                log.subjectAge = input('Subjects age? ','s');
                [age, valid] = str2num(log.subjectAge);
                if valid
                    log.subjectAge = age;
                    checkinput = false;
                else
                    fprintf('Please give a number as input.\n')
                end
            end
            fprintf('\n\n');
            fprintf ([...
                'You specified subject ' log.subjectNr '\n' ...
                'Language: ' log.language '\n' ...
                'Handedness: ' log.handedness '\n' ...
                'Dominant eye: ' log.dominantEye '\n' ...
                'Age: ' num2str(log.subjectAge) '\n'
                ])
            answer = input ('Are you sure you gave the right parameters?','s');
            if strcmp (answer, 'y')
                safetynet = false;
            end
            checkinput = true;
        end

        % call create subjectDir
        log = createSubDir(log);
        saveDir = fullfile(log.subjectDirectory,[log.sub 'logFile.mat']);
        save(saveDir,'log');

    catch INPUT_ERROR
        rethrow (INPUT_ERROR);
    end
end