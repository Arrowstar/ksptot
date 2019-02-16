function stop = optimplotxKsptot(x,optimValues,state,lb,ub,varLabels,lbUsAll,ubUsAll, varargin)
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
            lbUsAll = reshape(lbUsAll,size(x));
            ubUsAll = reshape(ubUsAll,size(x));
            xLength = length(x);
            xlabelText = getString(message('MATLAB:optimfun:funfun:optimplots:LabelNumberOfVariables',sprintf('%g',xLength)));

            % Display up to the first 100 values
            if length(x) > 100
                x = x(1:100);
                lb = lb(1:100);
                ub = ub(1:100);
                xLength = length(x);
                xlabelText = {xlabelText,getString(message('MATLAB:optimfun:funfun:optimplots:LabelShowingOnlyFirst100Variables'))};
            end

            x = (x-lb)./(ub-lb);
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

                rectWidth = plotx.BarWidth;
                for(i=1:length(x))
                    rects(i) = rectangle('Position',[i-rectWidth/2, 0, rectWidth, 1],'Curvature',0,'LineStyle','none'); %#ok<AGROW>
                    if(not(isempty(varLabels)) && length(varLabels) == length(x))
                        labels{i} = varLabels{i}; %#ok<AGROW>
                    else
                        labels{i} = sprintf('Var %u',i); %#ok<AGROW>
                    end
                end

                hAxes = ancestor(plotx,'axes');
                hPanel = get(hAxes,'Parent');
                hFig = ancestor(hAxes,'figure');
                
                tb = annotation(hPanel,'textbox');
                tb.Units = 'normalized';
                tb.Visible = 'off';
                tb.FontSize = 8;
                tb.HorizontalAlignment = 'center';
                tb.VerticalAlignment = 'middle';
                tb.Margin  = 5;
                tb.BackgroundColor = [255,255,224]/255;
                tb.LineWidth = 0.1;
                tb.FitBoxToText = 'off';
                tb.Position(4) = tb.Position(4)/2;
                
                hFig.WindowButtonMotionFcn = @(src,callbackdata) wbmcb(src,callbackdata, hAxes, hPanel, rects, labels, tb, lbUsAll,ubUsAll);
                
                setappdata(hAxes,'x',x);
            else
                plotx = findobj(get(gca,'Children'),'Tag','optimplotxksptot');
                set(plotx,'Ydata',x);

                ylim(gca,[0, 1]);
                set(gca,'YTickLabel',{'Lwr Bnd','Upr Bnd'});
                yticks(gca,[0 1]);
                
                hAxes = ancestor(plotx,'axes');
                setappdata(hAxes,'x',x);
            end
    end
end

function wbmcb(~,~, hAxes, hPanel, rects, labels, tb, lb, ub)
    cp = hAxes.CurrentPoint;
    
    
    found = false;
    for(i=1:length(rects))
        pos = rects(i).Position;
        xv = [pos(1), pos(1)+pos(3), pos(1)+pos(3), pos(1)];
        yv = [pos(2), pos(2), pos(2)+pos(4), pos(2)+pos(4)];
        
        xq = cp(2,1);
        yq = cp(2,2);
        
        in = inpolygon(xq,yq,xv,yv);
        
        if(in)
            x = getappdata(hAxes,'x');
            x = x.*(ub-lb)+lb; %unscale x
            varVal = x(i);
            
            str = sprintf('%s\n(Value: %0.3g)\n(Bounds: [%0.3g, %0.3g])',labels{i}, varVal, lb(i), ub(i));
            
            hT = text(hAxes,0,0,str, 'Units','normalized', 'FontSize',tb.FontSize, 'Visible','off', 'LineWidth',0.01, 'Margin',0.01);
            reqdWidth = hT.Extent(3) * hAxes.Position(3);
            reqdHeight = hT.Extent(4) * hAxes.Position(4);
            delete(hT);
            
            tb.String = str;
            tbPos = tb.Position;
            
            [figx, figy] = dsxy2figxy(hAxes, [xq xq],[yq yq]);     
            figx = figx(1);
            figy = figy(1);
            
            if(i >= length(rects)/2)
                figx = figx - reqdWidth;
            end
            
            tbPos(1:4) = [figx, figy, reqdWidth, reqdHeight];
            tb.Position = tbPos;
            
            found = true;
            break;
        end
    end
    
    if(found)
        tb.Visible='on';
    else
        tb.Visible='off';
    end
    
    drawnow;
end