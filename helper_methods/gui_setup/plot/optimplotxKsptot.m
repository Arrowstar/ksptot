function stop = optimplotxKsptot(x,optimValues,state,lb,ub,varargin)
% OPTIMPLOTX Plot current point at each iteration.
%
%   STOP = OPTIMPLOTX(X,OPTIMVALUES,STATE,LB,UB) plots the current point, X, as a
%   bar plot of its elements at the current iteration.
%
%   Example:
%   Create an options structure that will use OPTIMPLOTX
%   as the plot function
%       options = optimset('PlotFcns',@optimplotx);
%
%   Pass the options into an optimization problem to view the plot
%       fminbnd(@sin,3,10,options)

%   Copyright 2006-2010 The MathWorks, Inc.

stop = false;
switch state
    case 'iter'
        % Reshape if x is a matrix
        x = x(:);
        lb = reshape(lb,size(x));
        ub = reshape(ub,size(x));
        xLength = length(x);
        xlabelText = getString(message('MATLAB:optimfun:funfun:optimplots:LabelNumberOfVariables',sprintf('%g',xLength)));
        
        % Display up to the first 100 values
        if length(x) > 100
            x = x(1:100);
            lb = lb(1:100);
            ub = ub(1:100);
            xlabelText = {xlabelText,getString(message('MATLAB:optimfun:funfun:optimplots:LabelShowingOnlyFirst100Variables'))};
        end
        
        if optimValues.iteration == 0
            % The 'iter' case is  called during the zeroth iteration,
            % but it now has values that were empty during the 'init' case
            plotx = bar(x);
            title(getString(message('MATLAB:optimfun:funfun:optimplots:TitleCurrentPoint')),'interp','none');
            ylabel(getString(message('MATLAB:optimfun:funfun:optimplots:LabelCurrentPoint')),'interp','none');
            xlabel(xlabelText,'interp','none');
            set(plotx,'edgecolor','none')
            set(gca,'xlim',[0,1 + xLength])
            set(plotx,'Tag','optimplotxksptot');
            
            ylim(gca,[0, 1]);
            set(gca,'YTickLabel',{'Lwr Bnd','Upr Bnd'});
            yticks(gca,[0 1]);
        else
            plotx = findobj(get(gca,'Children'),'Tag','optimplotxksptot');
            x = (x-lb)./(ub-lb);
            set(plotx,'Ydata',x);

            ylim(gca,[0, 1]);
            set(gca,'YTickLabel',{'Lwr Bnd','Upr Bnd'});
            yticks(gca,[0 1]);
        end
end

