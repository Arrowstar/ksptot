classdef(Abstract) AbstractSteeringModel < matlab.mixin.SetGet
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        optVar
    end
    
    methods
        dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo)
                
        setConstsFromDcmAndContinuitySettings(obj, dcm, ut, rVect, vVect, bodyInfo)     
        
        setContinuityTerms(obj, angle1Cont, angle2Cont, angle3Cont)
        
        [angle1Cont, angle2Cont, angle3Cont] = getContinuityTerms(obj)
        
        enum = getSteeringModelTypeEnum(obj);
        
        newSteeringModel = deepCopy(obj)
        
        optVar = getNewOptVar(obj)
        
        optVar = getExistingOptVar(obj)
        
        function [addActionTf, steeringModel] = openEditSteeringModelUI(obj, lv)
            fakeAction = SetSteeringModelAction(obj);

            enum = obj.getSteeringModelTypeEnum();
            switch enum
                case SteerModelTypeEnum.PolyAngles
                    addActionTf = lvd_EditActionSetSteeringModelGUI(fakeAction, lv);

                case SteerModelTypeEnum.QuaterionInterp
                    addActionTf = lvd_EditActionSetQuatInterpSteeringModelGUI(fakeAction, lv);

                case SteerModelTypeEnum.LinearTangentAngles
                    addActionTf = lvd_EditActionSetLinearTangentSteeringModelGUI(fakeAction, lv);

                otherwise
                    error('Unknown steering model type: %s', enum.name);
            end

            steeringModel = fakeAction.steeringModel;
        end
    end
    
    methods(Static)
        model = getDefaultSteeringModel();
        
        typeStr = getTypeNameStr()
    end
end