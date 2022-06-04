function [sUnitVector, OUnitVector] = hyperOrbitExcessVelConstMath(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmu, hVInf)
%hyperOrbitExcessVelConstMath Summary of this function goes here
%   Detailed explanation goes here

    [~, ~, ~, ~, hOrbit, ~] = computeDepartArriveDVFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmu, hVInf);

    hSMA = hOrbit(1);
    hEcc = hOrbit(2);
    hInc = hOrbit(3);
    hRAAN = hOrbit(4);
    hArg = hOrbit(5);
    hTA = hOrbit(6);

%     [hRVect,hVVect]=getStatefromKepler(hSMA, hEcc, hInc, hRAAN, hArg, hTA, gmu);
% 
%     flyByAngle=2*asin(1/hEcc);
%     SigmaAngle=pi/2 - flyByAngle/2;
%     hUnitVector=hHat;
%     eVector=(norm(hVVect)^2/gmu - 1/norm(hRVect))*hRVect - (dot(hRVect,hVVect)/gmu)*hVVect;
%     eUnitVect=eVector/norm(eVector);
%     sUnitVector=cos(SigmaAngle)*eUnitVect + sin(SigmaAngle)*cross(hUnitVector,eUnitVect);
%     BUnitVector=cross(sUnitVector,hUnitVector)/norm(cross(sUnitVector,hUnitVector));
%     OUnitVector=cos(flyByAngle)*sUnitVector - sin(flyByAngle)*BUnitVector;

    [sUnitVector, OUnitVector] = computeHyperSVectOVect(hSMA, hEcc, hInc, hRAAN, hArg, hTA, gmu);
end

