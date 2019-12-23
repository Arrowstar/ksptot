classdef (Abstract) AbstractReferenceFrame < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractReferenceFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin] = getOffsetsWrtInertialOrigin(obj, time)
        
        bodyInfo = getOriginBody(obj)
        
        nameStr = getNameStr(obj)
    end
end