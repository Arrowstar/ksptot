function f = isSoICrossing(ut, scBodyInfo, childBodyInfo, bodyInfo, soiRadius, useAbs, celBodyData)
%isSoICrossing Summary of this function goes here
%   Detailed explanation goes here
    [rVectSC, ~] = getStateAtTime(scBodyInfo, ut, bodyInfo.gm);
    
    dVect = getAbsPositBetweenSpacecraftAndBody(ut, rVectSC, bodyInfo, childBodyInfo, celBodyData);
    dist = sqrt(sum(abs(dVect).^2,1));
    
    if(useAbs)
        f = abs(dist - soiRadius);
    else
        f = dist - soiRadius;
    end
end

