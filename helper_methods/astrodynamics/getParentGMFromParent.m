function [parentGm] = getParentGMFromParent(parentBodyInfo)
%getParentGM Summary of this function goes here
%   Detailed explanation goes here
    global options_gravParamType;
    
    switch options_gravParamType
        case 'kspStockLike'
            parentGm = parentBodyInfo.gm;
        case 'rssLike'
            parentGm = parentBodyInfo.gm + bodyInfo.gm;
        otherwise
            error('Unknown grav parameter option "%s"!', options_gravParamType);
    end
end