function [design] = designSettings(language,design)

if nargin < 2
    design = struct;
end

if strcmp (language, 'german')
    design.Introduction = ['Vielen Dank dass du an unserer Studie teilnimmst\n\n'...
        'Drücke eine beliebigen Knopf um fortzufahren'];
    design.Instruction1 = ['Drücke dies und drücke jenes'];
    design.Instruction2 = [''];
    design.Instruction3 = [''];
    
    design.FusionText   = ['Fusionstest: nutze die Pfeiltasten, um das Feld einzustellen. \n'...
        'Drücke "ENTER" um zu bestätigen'];
    
    design.RunIsOver =          '';
else
    %% English version of instructions
    design.Introduction = ['Thank you very much for participating in our study.\n\n'...
        'Press a botton to proceed.'];
    design.Instruction1 = ['Press this and press that'];
    design.Instruction2 = [''];
    design.Instruction3 = [''];
    
    design.FusionText   = 'Fusion test: use arrows to adjust or press "ENTER" to continue';
    design.RunIsOver =          'This run is now over';
end
end
