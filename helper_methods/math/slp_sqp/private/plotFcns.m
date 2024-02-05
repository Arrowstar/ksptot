function plotFcns( PlotFcn, x, out, state )
% Octave replacement for optimization toolbox's callAllOptimPlotFcns
persistent fignum mrow ncol plotFcnCell

if isOctave
   % Call fmincon's PlotFcns
   numplot = numel( PlotFcn );
   % open figure and store its #
   if strcmpi( state, 'init' )
      fignum = figure('Name','plotFcns');
      if numplot==4
         mrow = 2;
         ncol = 2;
      elseif numplot>1
         mrow = floor((numplot-1)/3)+1;
         ncol = rem(numplot-1,3)+1;
      end
   else
      figure( fignum );
   end
   if isa( PlotFcn, 'function_handle')
      PlotFcn( x, out, state );
   elseif isa( PlotFcn, 'char')
      feval( PlotFcn, x, out, state );
   elseif isa( PlotFcn, 'cell'  )
      for n=1:numel( PlotFcn )
         subplot(mrow,ncol,n)
         if isa( PlotFcn{n}, 'function_handle' )
            PlotFcn{n}( x, out, state );
         elseif isa( PlotFcn{n}, 'char' )
            feval( PlotFcn{n}, x, out, state );
         end
      end
   else
      error('plotFcns:handle','PlotFcn is not a (cell array of) function handle(s)')
   end

else % Equivalent optimization toolbox functions
   if strcmpi( state, 'init' )
      plotFcnCell = createCellArrayOfFunctions(PlotFcn,'PlotFcns');
   end
   callAllOptimPlotFcns(plotFcnCell, x, out, state);
end
end
