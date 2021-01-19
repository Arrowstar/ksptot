function topLevelBodyInfo = getTopLevelCentralBody(celBodyData)
    %getTopLevelCentralBody Summary of this function goes here
    %   Detailed explanation goes here   
    topLevelBodyInfo = celBodyData.emptyBodyInfo;
    celBodyFields = fields(celBodyData);
    for(i=1:length(celBodyFields))
        bInfo = celBodyData.(celBodyFields{i});
        
        if(isempty(bInfo.parentBodyInfo))
            topLevelBodyInfo = bInfo;
            break;
        end
    end
    
    if(isempty(topLevelBodyInfo))
        topLevelBodyInfo = celBodyData.(celBodyFields{1});
    end
end