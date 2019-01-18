
% Determine where your m-file's folder is.
folder = fileparts(which(mfilename)); 
% Add that folder plus all subfolders to the path.
addpath(genpath(folder));

%build Lambert
example_input = {...
                 [0.0, 0.0, 0.0], ...% r1vec
                 [0.0, 0.0, 0.0], ...% r2vec
                  0.0, ...           % tf
                  0.0, ...           % m
                  0.0};              % muC
codegen lambert.m -args example_input
clear example_input

%build AngleZero2Pi
example_input = {0.0};
codegen AngleZero2Pi.m -args example_input
clear example_input

%build angleNegPiToPi
example_input = {0.0};
codegen angleNegPiToPi.m -args example_input
clear example_input

%build crossARH
example_input = {[0;0;0], ...
                 [0;0;0]};
codegen crossARH.m -args example_input
clear example_input

%build dotARH
example_input = {[0;0;0], ...
                 [0;0;0]};
codegen dotARH.m -args example_input
clear example_input

%build getKeplerFromState_Alg
example_input = {[0;0;0], ...
                 [0;0;0], ...
                  0.0};
codegen getKeplerFromState_Alg.m -args example_input
clear example_input

%build getStatefromKepler_Alg
example_input = { 0.0, ...
                  0.0, ...
                  0.0, ...
                  0.0, ...
                  0.0, ...
                  0.0, ...
                  0.0};
codegen getStatefromKepler_Alg.m -args example_input
clear example_input