function [c, ceq] = hyperOrbitExcessVelConst(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmu, hVInf, hVInfIsOutbound)
%hyperOrbitExcessVelConst Summary of this function goes here
%   Detailed explanation goes here
    [sUnitVector, OUnitVector] = hyperOrbitExcessVelConstMath(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmu, hVInf);
    
    if(hVInfIsOutbound == 1)
        ceq = OUnitVector - hVInf/norm(hVInf);
    else %hVInf is the inbound vector
        ceq = sUnitVector - hVInf/norm(hVInf);
    end
    
    c=[];
end

