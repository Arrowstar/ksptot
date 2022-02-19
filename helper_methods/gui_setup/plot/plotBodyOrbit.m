function [h] = plotBodyOrbit(bodyInfo, color, gmuXfr, varargin)
%plotBodyOrbit Summary of this function goes here
%   Detailed explanation goes here
    if(~isempty(varargin))
        usePassedInColor = varargin{1};
    else
        usePassedInColor = false;
    end
    
    if(~isempty(varargin) && length(varargin)>=2)
        axisPlotTo = varargin{2};
    else
        axisPlotTo = gca;
    end
    
    try
        if(~isempty(varargin) && length(varargin)>=3)
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

    if(~usePassedInColor)
        try
            colorToPlot = colorFromColorMap(bodyInfo.bodycolor);
        catch ME
            colorToPlot = color;
        end
    else
        colorToPlot = color;
    end

    colorToPlot = [colorToPlot];
    
    dSMA = bodyInfo.sma;
    dECC = bodyInfo.ecc;
    dINC = bodyInfo.inc*pi/180;
    dRAAN = bodyInfo.raan*pi/180;
    dARG = bodyInfo.arg*pi/180;    
    h = plotOrbit(colorToPlot, dSMA, dECC, dINC, dRAAN, dARG, 0, 2*pi, gmuXfr, axisPlotTo, [], lineWidth, lineStyle);
end

