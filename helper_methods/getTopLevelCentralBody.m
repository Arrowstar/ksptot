function topLevelBodyInfo = getTopLevelCentralBody(celBodyData)
    %getTopLevelCentralBody Summary of this function goes here
    %   Detailed explanation goes here   
    try
        topLevelBodyInfo = celBodyData.emptyBodyInfo;
    catch
        topLevelBodyInfo = KSPTOT_BodyInfo.empty(1,0);
    end
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