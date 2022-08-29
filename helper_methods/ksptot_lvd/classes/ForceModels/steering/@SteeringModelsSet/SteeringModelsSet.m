classdef SteeringModelsSet < matlab.mixin.SetGet
    %SteeringModelsSet Summary of this class goes here
    %   Detailed explanation goes here

    properties
        polySteering(1,1) AbstractAnglePolySteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
        quatInterp(1,1) GenericQuatInterpSteeringModel = GenericQuatInterpSteeringModel.getDefaultSteeringModel();
        genericSelectableModels(1,1) GenericSelectableSteeringModel = GenericSelectableSteeringModel.getDefaultSteeringModel();

        selectedModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
    end

    methods
        function obj = SteeringModelsSet(polySteering, quatInterp, genericSelectableModels)
            arguments
                polySteering(1,1) AbstractAnglePolySteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
                quatInterp(1,1) GenericQuatInterpSteeringModel = GenericQuatInterpSteeringModel.getDefaultSteeringModel();
                genericSelectableModels(1,1) GenericSelectableSteeringModel = GenericSelectableSteeringModel.getDefaultSteeringModel();
            end

            obj.polySteering = polySteering;
            obj.quatInterp = quatInterp;
            obj.genericSelectableModels = genericSelectableModels;
            
            obj.selectedModel = obj.polySteering;
        end

        function set.selectedModel(obj, newSelectedModel)
            arguments
                obj(1,1) SteeringModelsSet
                newSelectedModel(1,1) AbstractSteeringModel
            end

            obj.selectedModel = newSelectedModel;

            enum = newSelectedModel.getSteeringModelTypeEnum();
            switch enum
                case SteerModelTypeEnum.PolyAngles
                    obj.polySteering = newSelectedModel; %#ok<MCSUP> 

                case SteerModelTypeEnum.QuaterionInterp
                    obj.quatInterp = newSelectedModel; %#ok<MCSUP> 

                case SteerModelTypeEnum.SelectableModelAngles
                    obj.genericSelectableModels = newSelectedModel; %#ok<MCSUP> 

                otherwise
                    error('Unknown steering model type: %s', enum.name);
            end
        end

        function useTf = openEditDialog(obj, lvdData, allowContinuity)
            out = AppDesignerGUIOutput({false});
            lvd_EditSteeringModelsSet_App(obj, lvdData, out, allowContinuity);
            useTf = out.output{1};
        end
    end
end