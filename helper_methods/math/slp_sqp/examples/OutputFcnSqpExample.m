function history = OutputFcnSqpExample( optimzr )

% Set up shared variables with OUTFUN
history.x = [];
history.fval = [];
history.maxg = [];

% Starting point and optimizer options
x0 = [-1 1];
PlotFcnCell={'optimplotx','optimplotfval','optimplotconstrviolation'};
options = optimset('OutputFcn',@outfun,'Display','iter',...
                   'PlotFcn',PlotFcnCell);
switch optimzr
   case 'sqp'
      % call sqp with OutputFcn
      [xsol,out] = sqp(@fcnsqp,x0,options);
      disp('sqp OutputFcn optimValues')
      disp(out)
      disp(xsol)
      
   case 'slp_trust'
      % call slp_trust with OutputFcn
      warning off
      options.MoveLimit = 0.5;
      options.TolOpt    = 1e-4;
      [~,~,~,out] = slp_trust(@fcnsqp,x0,options);
      disp('slp_trust OutputFcn optimValues')
      disp(out)
      warning on
      
   case 'fmincon'
      % call MATLAB toolbox fmincon optimization
      options = optimoptions(@fmincon,'Display','iter',...
         'OutputFcn',@outfun,'Algorithm','interior-point',...
         'PlotFcn',PlotFcnCell);
      fmincon(@objfun,x0,[],[],[],[],[],[],@confun,options);
end

 function stop = outfun(x,optimValues,state)
    persistent fignum
    switch state
       case 'init'
          fignum = figure('Name','outfun');
          hold on
       case 'iter'
          figure( fignum )
          % Concatenate current point and objective function
          % value with history. x must be a row vector.
          history.x = [history.x; x(:).'];
          history.fval = [history.fval; optimValues.fval];
          history.maxg = [history.maxg; optimValues.constrviolation];
          plot(x(1),x(2),'o');
          % Label points with iteration number and add title.
          % Add .15 to x(1) to separate label from plotted 'o'
          text(x(1)+.15,x(2),...
             num2str(optimValues.iteration));
          title(['Sequence of Points Computed by ',optimzr]);
       case 'done'
          figure( fignum )
          hold off
       otherwise
    end
     stop = false;
end
  
 function f = objfun(x)
     f = exp(x(1))*(4*x(1)^2 + 2*x(2)^2 + 4*x(1)*x(2) +... 
                    2*x(2) + 1);
 end
 
 function [c, ceq] = confun(x)
     % Nonlinear inequality constraints
     c = [1.5 + x(1)*x(2) - x(1) - x(2);
         -x(1)*x(2) - 10];
     % Nonlinear equality constraints
     ceq = [];
 end

 function [f,g] = fcnsqp(x)
    f = objfun(x);
    g = confun(x);
 end

end