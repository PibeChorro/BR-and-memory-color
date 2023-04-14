function [design] = designSettings(language)

if strcmp (language, 'german')
    design.Introduction =       ['Vielen Dank dass du an unserer Studie teilnimmst\n\n'...
        'Drücke eine beliebigen Knopf um fortzufahren'];
    design.Instruction1 =       ['Drücke dies und drücke jenes'];
    design.Instruction2 =       [''];
    design.Instruction3 =       [''];
    
    design.RunIsOver =          '';
else
    %% English version of instructions
    design.Introduction =       ['Thank you very much for participating in our study.\n\n'...
        'Press a botton to proceed.'];
    design.Instruction1 =       ['Press this and press that'];
    design.Instruction2 =       [''];
    design.Instruction3 =       [''];
    
    design.RunIsOver =          'This run is now over';
end
end
