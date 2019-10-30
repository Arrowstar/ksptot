classdef(Abstract) AbstractSteeringModel < matlab.mixin.SetGet
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        optVar
    end
    
    methods
        dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo)
        
        setT0(obj, newT0)
        
        setConstTerms(obj, angle1, angle2, angle3)
        
        setLinearTerms(obj, angle1, angle2, angle3)
        
        setAccelTerms(obj, angle1, angle2, angle3)
        
        setConstsFromDcmAndContinuitySettings(obj, dcm, ut, rVect, vVect, bodyInfo)     
        
        setContinuityTerms(obj, angle1Cont, angle2Cont, angle3Cont)
        
        [angle1Cont, angle2Cont, angle3Cont] = getContinuityTerms(obj)
        
        newSteeringModel = deepCopy(obj)
        
        optVar = getNewOptVar(obj)
        
        optVar = getExistingOptVar(obj)
        
        addActionTf = openEditSteeringModelUI(obj, lv)
    end
    
    methods(Static)
        typeStr = getTypeNameStr()
    end
end