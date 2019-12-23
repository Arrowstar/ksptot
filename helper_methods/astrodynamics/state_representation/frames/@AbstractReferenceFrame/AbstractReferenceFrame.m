classdef (Abstract) AbstractReferenceFrame < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.CustomDisplay
    %AbstractReferenceFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin] = getOffsetsWrtInertialOrigin(obj, time)
        
        bodyInfo = getOriginBody(obj)
        
        nameStr = getNameStr(obj)
    end
    
    methods(Access=protected)
        function displayScalarObject(obj)
            fprintf(obj.getNameStr());
        end        
    end
end