function stop = outfunExampleOctave(x,optimValues,state)
global     OUTFUN_HISTORY
persistent fignum history
switch state
   case 'init'
      fignum = figure('Name','outfun');
      hold on
      history.x = [];
      history.fval = [];
      history.maxg = [];
   case 'iter'
      figure( fignum )
      % Concatenate current point and objective function
      % value with history. x must be a row vector.
      
      history.x = [history.x; x(:).'];
      history.fval = [history.fval; optimValues.fval];
      history.maxg = [history.maxg; optimValues.constrviolation];
%     history.lambda{optimValues.iteration+1} = optimValues.lambda;
      plot(x(1),x(2),'o');
      % Label points with iteration number and add title.
      % Add .15 to x(1) to separate label from plotted 'o'
      text(x(1)+.15,x(2),...
         num2str(optimValues.iteration));
      title('Sequence of Design Points');
   case 'done'
      figure( fignum )
      hold off
      OUTFUN_HISTORY = history;
   otherwise
end
stop = false;
end
