function [rVectECEF, vVectECEF, REci2Ecef] = getFixedFrameVectFromInertialVect_alg(ut, rVectECI, rotperiod, rotini, varargin)
%getFixedFrameVectFromInertialVect Summary of this function goes here 
%   Detailed explanation goes here

    if(~isempty(varargin))
        vVectECI = varargin{1};
    else
        vVectECI = [NaN;NaN;NaN];
    end

    numElems = length(ut);
    
    spinAngle = getBodySpinAngle_alg(rotperiod, rotini, ut);
    
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
     
    rVectECI = reshape(rVectECI,3,1,numElems);
    REci2Ecef = permute(R,[2,1,3]); %ND transpose
    rVectECEF = mtimesx(REci2Ecef, rVectECI);
    rVectECEF = reshape(rVectECEF,3,numElems);
        
    if(~any(isnan(vVectECI)))
        rotRateRadSec = 2*pi/rotperiod;
        omegaRI = repmat([0;0;rotRateRadSec],1,numElems);
        vVectECI = reshape(vVectECI,3,1,numElems);
        
        vVectECEF = mtimesx(REci2Ecef, (vVectECI - cross(omegaRI, rVectECI)));
        vVectECEF = reshape(vVectECEF,3,numElems);
    else
        vVectECEF = repmat([NaN;NaN;NaN],1,numElems);
    end
end