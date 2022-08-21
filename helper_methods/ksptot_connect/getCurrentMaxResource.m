function [current, max] = getCurrentMaxResource(resourceStruct, resName)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

    resName = lower(resName);

    current = 0;
    max = 0;
    if(isfield(resourceStruct, resName))
        rArr = resourceStruct.(resName);
        for(i=1:size(rArr,1))
            current = current + rArr{i,4};
            max = max + rArr{i,5};
        end
    else
        current = 0;
        max = 0;
    end
end

