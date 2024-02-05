function history = OutputPlotFcnsExampleOctave( optimzr )

% Set up shared variables with OUTFUN
global OUTFUN_HISTORY

% anonymous functions for optimizer exampleand starting point
f = @(x) exp(x(1))*(4*x(1)^2 + 2*x(2)^2 + 4*x(1)*x(2) + 2*x(2) + 1); % obj
g = @(x) [1.5 + x(1)*x(2) - x(1) - x(2); - x(1)*x(2) - 10]; % inequality
disp('Initial x0 function values')
x0 = [-1 1] 
funeval = @(x) fghx( x, f, g ); % Octave does not support nested functions
[obj,con] = funeval( x0 ) %#ok<*NOPRT,ASGLU>

%% Optimizer options
options = optimset('OutputFcn',@outfunExampleOctave,'Display','iter');
if ~isempty(which('optimplotx'))
options.PlotFcns={'optimplotx','optimplotfval','optimplotconstrviolation'};
end
switch optimzr
   
   case 'sqp'
      % call sqp with OutputFcn
      options.MaxIter = 20;
%     options.Display = 'debug';
      [xsol,out] = sqp(funeval,x0,options);
      disp('sqp OutputFcn optimValues')
      disp(out)
      disp(xsol)
      
   case {'slp', 'slp_trust'}
      % call slp_trust with OutputFcn
      warning off
      options.MoveLimit = 0.5;
      options.TolOpt    = 1e-4;
      options.TolX      = 0.01;
      xslp = slp_trust(@fgx,x0,options,[],[],[],[],[],[],[],{f,g}) %#ok<NASGU>
      warning on
end

history = OUTFUN_HISTORY;

end