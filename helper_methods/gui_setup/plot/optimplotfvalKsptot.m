function stop = optimplotfvalKsptot(~,optimValues,state,varargin)
% OPTIMPLOTFVAL Plot value of the objective function at each iteration.
%
%   STOP = OPTIMPLOTFVAL(X,OPTIMVALUES,STATE) plots OPTIMVALUES.fval.  If
%   the function value is not scalar, a bar plot of the elements at the
%   current iteration is displayed.  If the OPTIMVALUES.fval field does not
%   exist, the OPTIMVALUES.residual field is used.
%
%   Example:
%   Create an options structure that will use OPTIMPLOTFVAL as the plot
%   function
%     options = optimset('PlotFcns',@optimplotfval);
%
%   Pass the options into an optimization problem to view the plot
%     fminbnd(@sin,3,10,options)

%   Copyright 2006-2010 The MathWorks, Inc.

stop = false;
switch state
    case 'iter'
        if isfield(optimValues,'fval')
            if isscalar(optimValues.fval)
                plotscalar(optimValues.iteration,optimValues.fval);
            else
                plotvector(optimValues.iteration,optimValues.fval);
            end
        else
            plotvector(optimValues.iteration,optimValues.residual);
        end
end

function plotscalar(iteration,fval)
% PLOTSCALAR initializes or updates a line plot of the function value
% at each iteration.
persistent plotfval plotfvalParent

if iteration == 0
    plotfval = plot(iteration,fval,'kd','MarkerFaceColor',[1 0 1]);
    plotfvalParent = plotfval.Parent;
    title(getString(message('MATLAB:optimfun:funfun:optimplots:TitleCurrentFunctionValue',sprintf('%g',fval))),'interp','none');
    xlabel(getString(message('MATLAB:optimfun:funfun:optimplots:LabelIteration')),'interp','none');
    set(plotfval,'Tag','optimplotfval');
    ylabel(getString(message('MATLAB:optimfun:funfun:optimplots:LabelFunctionValue')),'interp','none')
else
%     plotfval = findobj(get(gca,'Children'),'Tag','optimplotfval');
%     plotfval.Parent = plotfvalParent;
    newX = [get(plotfval,'Xdata') iteration];
    newY = [get(plotfval,'Ydata') fval];
    set(plotfval,'Xdata',newX, 'Ydata',newY);
    set(get(plotfvalParent,'Title'),'String',getString(message('MATLAB:optimfun:funfun:optimplots:TitleCurrentFunctionValue',sprintf('%g',fval))));
end

function plotvector(iteration,fval)
% PLOTVECTOR creates or updates a bar plot of the function values or
% residuals at the current iteration.
persistent plotfval

if iteration == 0
    xlabelText = getString(message('MATLAB:optimfun:funfun:optimplots:LabelNumberOfFunctionValues0',sprintf('%g',length(fval))));
    % display up to the first 100 values
    if numel(fval) > 100
        xlabelText = {xlabelText,getString(message('MATLAB:optimfun:funfun:optimplots:LabelShowingOnlyFirst100Values'))};
        fval = fval(1:100);
    end
    plotfval = bar(fval);
    title(getString(message('MATLAB:optimfun:funfun:optimplots:TitleCurrentFunctionValues')),'interp','none');
    set(plotfval,'edgecolor','none')
    set(plotfvalParent,'xlim',[0,1 + length(fval)])
    xlabel(xlabelText,'interp','none')
    set(plotfval,'Tag','optimplotfval');
    ylabel(getString(message('MATLAB:optimfun:funfun:optimplots:LabelFunctionValue')),'interp','none')
else
%     plotfval = findobj(get(gca,'Children'),'Tag','optimplotfval');
    % display up to the first 100 values
    if numel(fval) > 100
        fval = fval(1:100);
    end
    set(plotfval,'Ydata',fval);
end
