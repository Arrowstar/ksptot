function [rVectECI, vVectECI] = getInertialVectFromFixedFrameVect(ut, rVectECEF, bodyInfo, vVectECEF)
%getInertialVectFromFixedFrameVect Summary of this function goes here
%   Detailed explanation goes here
    numElems = length(ut);

    spinAngle = getBodySpinAngle(bodyInfo, ut);
    
    cSA = reshape(cos(spinAngle),1,1,numElems);
    sSA = reshape(sin(spinAngle),1,1,numElems);
    zero = zeros(1,1,numElems);
    one = zero + 1;
    
%     R = [cos(spinAngle) -sin(spinAngle) 0;
%          sin(spinAngle) cos(spinAngle) 0;
%          0 0 1];

    R = [cSA, -sSA, zero;
         sSA, cSA, zero;
         zero, zero, one];
     
    rVectECEF = reshape(rVectECEF,3,1,numElems);
%     rVectECI = R * rVectECEF;
    rVectECI = mtimesx(R,rVectECEF);
    rVectECI = reshape(rVectECI,3,numElems);
     
    rotRateRadSec = 2*pi/bodyInfo.rotperiod;
    omegaRI = repmat([0;0;rotRateRadSec],1,1,numElems);
    vVectECEF = reshape(vVectECEF,3,1,numElems);
%     vVectECI = R*(vVectECEF + cross(omegaRI, rVectECEF));
    vVectECI = mtimesx(R,(vVectECEF + cross(omegaRI, rVectECEF)));
    vVectECI = reshape(vVectECI,3,numElems);
end

