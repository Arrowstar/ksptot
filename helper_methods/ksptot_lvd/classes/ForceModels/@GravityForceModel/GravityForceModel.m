classdef GravityForceModel < AbstractForceModel
    %GravityForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = GravityForceModel()
            
        end
        
        function [forceVect, tankMdots, ecStgDots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~)
            if(bodyInfo.usenonsphericalgrav == false || (bodyInfo.usenonsphericalgrav == true && bodyInfo.nonsphericalgravmaxdeg == 0))
                r = norm(rVect);
                forceVect = -((bodyInfo.gm * mass)/(r^3)) * rVect; %km^3/s^2 * mT / km^2 = km*mT/s^2
            else
                elemSet = CartesianElementSet(ut, rVect, vVect, bodyInfo.getBodyCenteredInertialFrame());
                %elemSet is constructed in this body's own BCI frame, so use
                %the fast-path variant that skips the (expensive) frame
                %equality test performed by the generic function.
                gInertial = gravitysphericalharmonicARH_bci(elemSet, bodyInfo);
                forceVect = gInertial * mass;
            end
            
            tankMdots = [];
            ecStgDots = [];
        end
    end
end