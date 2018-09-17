classdef(Abstract) AbstractSteeringModel < matlab.mixin.SetGet
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        optVar
    end
    
    methods
        dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect)
        
        setT0(obj, newT0)
        
        setConstTerms(obj, angle1, angle2, angle3)
        
        setLinearTerms(obj, angle1, angle2, angle3)
        
        setAccelTerms(obj, angle1, angle2, angle3)
        
        setConstsFromDcmAndContinuitySettings(obj, dcm, rVect, vVect)     
        
        optVar = getNewOptVar(obj)
    end
    
    methods(Static)
        typeStr = getTypeNameStr()
    end
end