function [parentBodyInfo] = getParentBodyInfo(bodyInfo, celBodyData)
%getParentBodyInfo Summary of this function goes here
%   Detailed explanation goes here

    parentName = lower(bodyInfo.parent);
    if(isfield(celBodyData,parentName))
        parentBodyInfo = celBodyData.(parentName);
    else
        parentBodyInfo = [];
    end
end