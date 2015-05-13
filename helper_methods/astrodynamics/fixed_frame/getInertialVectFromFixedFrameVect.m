function [rVectECI] = getInertialVectFromFixedFrameVect(ut, rVectECEF, bodyInfo)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    spinAngle = getBodySpinAngle(bodyInfo, ut);
    
    R = [cos(spinAngle) -sin(spinAngle) 0;
         sin(spinAngle) cos(spinAngle) 0;
         0 0 1];
     
     rVectECEF = reshape(rVectECEF,3,1);
     rVectECI = R * rVectECEF;
end

