function [c, ceq] = hyperOrbitExcessVelConst(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmu, hVInf, hVInfIsOutbound)
%hyperOrbitExcessVelConst Summary of this function goes here
%   Detailed explanation goes here
    [sUnitVector, OUnitVector] = hyperOrbitExcessVelConstMath(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmu, hVInf);
    
    if(hVInfIsOutbound == 1)
        vect = OUnitVector - hVInf/norm(hVInf);
    else %hVInf is the inbound vector
        vect = sUnitVector - hVInf/norm(hVInf);
    end
    %disp(max(vect));
    ceq = vect;
    c=[];
end

