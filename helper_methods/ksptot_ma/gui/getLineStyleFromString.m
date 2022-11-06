function [lineStyle] = getLineStyleFromString(linestyleStr)
%getLineStyleFromString Summary of this function goes here
%   Detailed explanation goes here

    switch linestyleStr
        case '-'
            lineStyle = 'Solid Line';
        case '--'
            lineStyle = 'Dashed Line';
        case ':'
            lineStyle = 'Dotted Line';
        case '-.'
            lineStyle = 'Dashed-dot Line';
        otherwise
            lineStyle = 'Dashed Line';
    end
end

