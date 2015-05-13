function [rVectECEF] = getFixedFrameVectFromInertialVect(ut, rVectECI, bodyInfo)
%getFixedFrameVectFromInertialVect Summary of this function goes here
%   Detailed explanation goes here

    spinAngle = getBodySpinAngle(bodyInfo, ut);
    
    R = [cos(spinAngle) -sin(spinAngle) 0;
         sin(spinAngle) cos(spinAngle) 0;
         0 0 1];
    rVectECI = reshape(rVectECI,3,1);
    
    rVectECEF = R' * rVectECI;
end

