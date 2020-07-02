classdef(Abstract) AbstractOrbitStateModel < matlab.mixin.SetGet
    %AbstractOrbitStateModel Summary of this class goes here
    %   Detailed explanation goes here

    methods
        [rVect, vVect] = getPositionAndVelocityVector(obj, ut, bodyInfo)
        
        elemVect = getElementVector(obj)
    end
    
    methods(Static)
        defaultOrbitState = getDefaultOrbitState()
        
        errMsg = validateInputOrbit(errMsg, hOrbit1, hOrbit2, hOrbit3, hOrbit4, hOrbit5, hOrbit6, bodyInfo)
    end
end

