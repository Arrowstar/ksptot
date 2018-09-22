classdef(Abstract) AbstractOrbitStateModel < matlab.mixin.SetGet
    %AbstractOrbitStateModel Summary of this class goes here
    %   Detailed explanation goes here

    methods
        [rVect, vVect] = getPositionAndVelocityVector(obj, ut, bodyInfo)
    end
end

