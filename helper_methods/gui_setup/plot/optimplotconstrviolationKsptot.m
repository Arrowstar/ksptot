function stop = optimplotconstrviolationKsptot(x,optimValues,state,varargin)
% OPTIMPLOTCONSTRVIOLATION Plot max constraint violation at each iteration.
%
%   STOP = OPTIMPLOTCONSTRVIOLATION(X,OPTIMVALUES,STATE) plots
%   OPTIMVALUES.constrviolation.
%
%   Example:
%   Create an options structure that will use OPTIMPLOTCONSTRVIOLATION as 
%   the plot function
%     options = optimoptions('fmincon','PlotFcn',@optimplotconstrviolation);
%
%   Pass the options into an optimization problem to view the plot
%      fmincon(@(x) 3*sin(x(1))+exp(x(2)),[1;1],[],[],[],[],[0 0],[],[],options)

%   Copyright 2006-2015 The MathWorks, Inc.

persistent plotavailable plotconstrviolation plotconstrviolationParent
stop = false;

switch state
    case 'init'
        if isfield(optimValues,'constrviolation')
            plotavailable = true;
        else
            plotavailable = false;
            title(getString(message('optim:optimplot:TitleMaxConstrViol', ...
                    getString(message('optim:optimplot:NotAvailable')))),'interp','none');
        end
    case 'iter'
        if plotavailable
            if optimValues.iteration == 0
                % The 'iter' case is  called during the zeroth iteration,
                % but it now has values that were empty during the 'init' case
                plotconstrviolation = plot(optimValues.iteration,optimValues.constrviolation,'kd', ...
                    'MarkerFaceColor',[1 0 1]);
                plotconstrviolationParent = plotconstrviolation.Parent;
                title(getString(message('optim:optimplot:TitleMaxConstrViol', ...
                    sprintf('%g',optimValues.constrviolation))),'interp','none');
                xlabel(getString(message('optim:optimplot:XlabelIter')),'interp','none');
                ylabel(getString(message('optim:optimplot:YlabelConstrViol')),'interp','none');
                set(plotconstrviolation,'Tag','optimplotconstrviolation');
            else
%                 plotconstrviolation = findobj(get(gca,'Children'),'Tag','optimplotconstrviolation');
%                 plotconstrviolation.Parent = plotconstrviolationParent;
                newX = [get(plotconstrviolation,'Xdata') optimValues.iteration];
                newY = [get(plotconstrviolation,'Ydata') optimValues.constrviolation];
                set(plotconstrviolation,'Xdata',newX, 'Ydata',newY);
                set(get(plotconstrviolationParent,'Title'),'String', ...
                    getString(message('optim:optimplot:TitleMaxConstrViol', ...
                    sprintf('%g',optimValues.constrviolation))));
            end
        end
end
