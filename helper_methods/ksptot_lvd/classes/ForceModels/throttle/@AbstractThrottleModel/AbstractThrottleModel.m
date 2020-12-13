classdef(Abstract) AbstractThrottleModel < matlab.mixin.SetGet
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        optVar
        
        throttleContinuity = false;
    end
    
    methods
        initThrottleModel(obj, ut, prevThrottleAtUt)
        
        throttle = getThrottleAtTime(obj, ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates)
                
        enum = getThrottleModelTypeEnum(obj);
        
        function [addActionTf, throttleModel] = openEditThrottleModelUI(obj, lv)
            fakeAction = SetThrottleModelAction(obj);
            
            enum = obj.getThrottleModelTypeEnum();
            switch enum
                case ThrottleModelEnum.PolyModel
                    addActionTf = lvd_EditActionSetThrottleModelGUI(fakeAction, lv);
                    
                case ThrottleModelEnum.T2WModel
                    addActionTf = lvd_EditT2WThrottleModelGUI(fakeAction, lv);
                    
                otherwise
                    error('Unknown throttle model type: %s', enum.nameStr);
            end
            
            throttleModel = fakeAction.throttleModel;
        end
        
        optVar = getNewOptVar(obj)
        
        optVar = getExistingOptVar(obj)
        
        setT0(obj,t0);
    end
end