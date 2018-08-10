function [celBodyData] = setParentBodyInfo(celBodyData)
%setParentBodyInfo Summary of this function goes here
%   Detailed explanation goes here
    bodyNames = fieldnames(celBodyData);

    for(i=1:length(bodyNames)) %#ok<*NO4LP>
        bodyName = bodyNames{i};
        bodyInfo = celBodyData.(lower(bodyName));
        
        bodyInfo.parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
        celBodyData.(lower(bodyName)) = bodyInfo;
    end
end

