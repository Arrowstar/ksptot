classdef(Abstract) AbstractSteeringModel < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        optVar
    end
    
    methods
        t0 = getT0(obj)
        
        setT0(obj, newT0)
        
        dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo)
                
        setConstsFromDcmAndContinuitySettings(obj, dcm, ut, rVect, vVect, bodyInfo) 
        
        setInitialAttitudeFromState(obj, stateLogEntry, tOffsetDelta)
        
        setContinuityTerms(obj, angle1Cont, angle2Cont, angle3Cont)
        
        [angle1Cont, angle2Cont, angle3Cont] = getContinuityTerms(obj)
        
        enum = getSteeringModelTypeEnum(obj);
        
        newSteeringModel = deepCopy(obj)
        
        optVar = getNewOptVar(obj)
        
        optVar = getExistingOptVar(obj)

        [addActionTf, steeringModel] = openEditSteeringModelUI(obj, lv, useContinuity)
    end
    
    methods(Static)
        model = getDefaultSteeringModel();
        
        typeStr = getTypeNameStr()
    end
end