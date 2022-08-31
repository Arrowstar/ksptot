function [outStr] = paddStrLeft(str, desLength)
%paddStr Summary of this function goes here
%   Detailed explanation goes here
    outStr = str;
    while(length(outStr) < desLength)
        outStr = [' ',outStr];
    end
end

