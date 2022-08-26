classdef ThrottleModelsSet < matlab.mixin.SetGet
    %SteeringModelsSet Summary of this class goes here
    %   Detailed explanation goes here

    properties
        polyThrottle(1,1) ThrottlePolyModel = ThrottlePolyModel.getDefaultThrottleModel();
        t2wThrottle(1,1) T2WThrottleModel = T2WThrottleModel.getDefaultThrottleModel();

        selectedModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();
    end

    methods
        function obj = ThrottleModelsSet(polyThrottle, t2wThrottle)
            arguments
                polyThrottle(1,1) ThrottlePolyModel = ThrottlePolyModel.getDefaultThrottleModel();
                t2wThrottle(1,1) T2WThrottleModel = T2WThrottleModel.getDefaultThrottleModel();
            end

            obj.polyThrottle = polyThrottle;
            obj.t2wThrottle = t2wThrottle;
            
            obj.selectedModel = obj.polyThrottle;
        end

        function set.selectedModel(obj, newSelectedModel)
            arguments
                obj(1,1) ThrottleModelsSet
                newSelectedModel(1,1) AbstractThrottleModel
            end

            obj.selectedModel = newSelectedModel;

            enum = newSelectedModel.getThrottleModelTypeEnum();
            switch enum
                case ThrottleModelEnum.PolyModel
                    obj.polyThrottle = newSelectedModel; %#ok<MCSUP> 

                case ThrottleModelEnum.T2WModel
                    obj.t2wThrottle = newSelectedModel; %#ok<MCSUP> 

                otherwise
                    error('Unknown throttle model type: %s', enum.name);
            end
        end

        function useTf = openEditDialog(obj, lvdData, allowContinuity)
            out = AppDesignerGUIOutput({false});
            lvd_EditThrottleModelsSet_App(obj, lvdData, out, allowContinuity);
            useTf = out.output{1};
        end
    end
end