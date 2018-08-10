function [rVectECI, vVectECI] = getInertialVectFromFixedFrameVect(ut, rVectECEF, bodyInfo, vVectECEF)
%getInertialVectFromFixedFrameVect Summary of this function goes here
%   Detailed explanation goes here

    spinAngle = getBodySpinAngle(bodyInfo, ut);
    
    R = [cos(spinAngle) -sin(spinAngle) 0;
         sin(spinAngle) cos(spinAngle) 0;
         0 0 1];
     
    rVectECEF = reshape(rVectECEF,3,1);
    rVectECI = R * rVectECEF;
     
    rotRateRadSec = 2*pi/bodyInfo.rotperiod;
    omegaRI = [0;0;rotRateRadSec];
    vVectECI = R*(vVectECEF + crossARH(omegaRI, rVectECEF));
end

