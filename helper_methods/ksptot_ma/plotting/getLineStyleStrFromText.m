function [lineStyle] = getLineStyleStrFromText(lineStyleText)
%getLineStyleFromString Summary of this function goes here
%   Detailed explanation goes here

    switch lineStyleText
        case 'Solid Line'
            lineStyle = '-';
        case 'Dashed Line'
            lineStyle = '--';
        case 'Dotted Line'
            lineStyle = ':';
        case 'Dashed-dot Line'
            lineStyle = '-.';
        otherwise
            lineStyle = '-';
    end
end

