function [parentGm] = getParentGM(bodyInfo, celBodyData)
%getParentGM Summary of this function goes here
%   Detailed explanation goes here
    global options_gravParamType;
    
    try
        parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
    catch 
        parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
    end
    
    if(not(isempty(parentBodyInfo)))
        switch options_gravParamType
            case 'kspStockLike'
                parentGm = parentBodyInfo.gm;
            case 'rssLike'
                parentGm = parentBodyInfo.gm + bodyInfo.gm;
            otherwise
                error('Unknown grav parameter option "%s"!', options_gravParamType);
        end
    else
        parentGm = 0;
    end
end