classdef (Abstract) AbstractReferenceFrame < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.CustomDisplay
    %AbstractReferenceFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Abstract, Constant)
        typeEnum
    end
    
    properties(Transient)
        timeCache(1,1) double = NaN
        posOffsetOriginCache(3,1) double
        velOffsetOriginCache(3,1) double
        angVelWrtOriginCache(3,1) double
        rotMatToInertialCache(3,3) double
    end
    
    methods
        [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time, vehElemSet)
        
        bodyInfo = getOriginBody(obj)
        
        setOriginBody(obj, newBodyInfo)
        
        nameStr = getNameStr(obj)
        
        editFrameDialogUI(obj, context)
    end
    
    methods(Access=protected)
        function displayScalarObject(obj)
            fprintf('%s\n',obj.getNameStr());
        end        
    end
end