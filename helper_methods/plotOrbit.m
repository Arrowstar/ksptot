function h = plotOrbit(color, sma, ecc, inc, raan, arg, minTru, maxTru, gmu, varargin)
%plotOrbit Summary of this function goes here
%   Detailed explanation goes here
    if(minTru >= maxTru)
        h=plotOrbit(color, sma, ecc, inc, raan, arg, minTru, 2*pi, gmu, varargin{:});
        plotOrbit(color, sma, ecc, inc, raan, arg, 0, maxTru, gmu, varargin{:});
        return;
    end
    
    if(~isempty(varargin) && ~isempty(varargin{1}))
        axisPlotTo = varargin{1};
    else
        axisPlotTo = gca;
    end

    try
        if(~isempty(varargin) && length(varargin)>=2)
            if(length(varargin{2}) == 3)
                rOffset = reshape(varargin{2},3,1);
            else
                rOffset = [0;0;0];
            end
        else
            rOffset = [0;0;0];
        end
    catch
        rOffset = [0;0;0];
    end
    
    try
        if(~isempty(varargin) && length(varargin)>=3 && length(varargin{3}) == 1)
            lineWidth = varargin{3};
        else
            lineWidth = 1.5;
        end
    catch
        lineWidth = 1.5;
    end
    
    if(~isempty(varargin) && length(varargin)>=4)
        lineStyle = varargin{4};
    else
        lineStyle = '-';
    end
    
    tru = linspace(minTru,maxTru,250);
    zeroArr = zeros(size(tru));
    sma = zeroArr + sma;
    ecc = zeroArr + ecc;
    inc = zeroArr + inc;
    raan = zeroArr + raan;
    arg = zeroArr + arg;
    
    [rVect,~] = vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu, false);
    x = rVect(1,:) + rOffset(1);
    y = rVect(2,:) + rOffset(2);
    z = rVect(3,:) + rOffset(3);

    hold(axisPlotTo,'on');
    if(ischar(color))
        colorNew = color;
        try
            h = plot3(axisPlotTo, x,y,z, 'Color', colorNew, 'LineWidth', lineWidth, 'LineStyle', lineStyle);
        catch
            h = plot3(axisPlotTo, x,y,z, 'Color', color, 'LineWidth', lineWidth, 'LineStyle', lineStyle);
        end
    else
        
        h = plot3(axisPlotTo, x,y,z, lineStyle, 'Color', color, 'LineWidth', lineWidth);
    end
    
    hold(axisPlotTo,'off');
end