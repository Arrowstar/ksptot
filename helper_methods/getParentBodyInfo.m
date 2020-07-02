function [parentBodyInfo] = getParentBodyInfo(bodyInfo, celBodyData)
%getParentBodyInfo Summary of this function goes here
%   Detailed explanation goes here

    parentName = lower(bodyInfo.parent);
    if(isfield(celBodyData,parentName))
        if(isempty(fieldnames(celBodyData)))
            parentBodyInfo = bodyInfo.celBodyData.(parentName);
        else
            parentBodyInfo = celBodyData.(parentName);
        end
    else
        parentBodyInfo = [];
    end
end