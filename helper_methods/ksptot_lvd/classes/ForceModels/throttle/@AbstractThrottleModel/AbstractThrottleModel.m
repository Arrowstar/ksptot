classdef(Abstract) AbstractThrottleModel < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        optVar
        
        throttleContinuity = false;
    end
    
    methods
        initThrottleModel(obj, initialStateLogEntry) 
        
        setInitialThrottleFromState(obj, stateLogEntry, tOffsetDelta)
        
        throttle = getThrottleAtTime(obj, ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates)
                
        enum = getThrottleModelTypeEnum(obj);
        
%         function [addActionTf, throttleModel] = openEditThrottleModelUI(obj, lv, useContinuity)
%             fakeAction = SetThrottleModelAction(obj);
%             
%             enum = obj.getThrottleModelTypeEnum();
%             switch enum
%                 case ThrottleModelEnum.PolyModel
% %                     addActionTf = lvd_EditActionSetThrottleModelGUI(fakeAction, lv, useContinuity);
%                     
%                     output = AppDesignerGUIOutput({false});
%                     lvd_EditActionSetThrottleModelGUI_App(fakeAction, lv, useContinuity, output);
%                     addActionTf = output.output{1};
%                     
%                 case ThrottleModelEnum.T2WModel
% %                     addActionTf = lvd_EditT2WThrottleModelGUI(fakeAction, lv, useContinuity);
%                     
%                     output = AppDesignerGUIOutput({false});
%                     lvd_EditT2WThrottleModelGUI_App(fakeAction, lv, useContinuity, output);
%                     addActionTf = output.output{1};
%                     
%                 otherwise
%                     error('Unknown throttle model type: %s', enum.nameStr);
%             end
%             
%             throttleModel = fakeAction.throttleModel;
%         end
        
        optVar = getNewOptVar(obj)
        
        optVar = getExistingOptVar(obj)
        
        t0 = getT0(obj);
        
        setT0(obj,t0);
    end
end