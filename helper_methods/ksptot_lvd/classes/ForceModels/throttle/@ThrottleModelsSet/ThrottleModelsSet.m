classdef ThrottleModelsSet < matlab.mixin.SetGet
    %SteeringModelsSet Summary of this class goes here
    %   Detailed explanation goes here

    properties
        polyThrottle(1,1) ThrottlePolyModel = ThrottlePolyModel.getDefaultThrottleModel();
        t2wThrottle(1,1) T2WThrottleModel = T2WThrottleModel.getDefaultThrottleModel();
        tabularInterpThrottle(1,1) ThrottleInterpolatedModel = ThrottleInterpolatedModel.getDefaultThrottleModel();
        limitedThrottle(1,1) LimitedThrottleModel = LimitedThrottleModel.getDefaultThrottleModel();

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
            obj.limitedThrottle = LimitedThrottleModel.getDefaultThrottleModel();

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

                case ThrottleModelEnum.InterpThrottle
                    obj.tabularInterpThrottle = newSelectedModel; %#ok<MCSUP> 

                case ThrottleModelEnum.Limited
                    obj.limitedThrottle = newSelectedModel; %#ok<MCSUP> 

                otherwise
                    error('Unknown throttle model type: %s', enum.name);
            end
        end

        function model = getModelForEnum(obj, enum)
            %getModelForEnum Returns the stored model of the given type.
            arguments
                obj(1,1) ThrottleModelsSet
                enum(1,1) ThrottleModelEnum
            end

            switch enum
                case ThrottleModelEnum.PolyModel
                    model = obj.polyThrottle;

                case ThrottleModelEnum.T2WModel
                    model = obj.t2wThrottle;

                case ThrottleModelEnum.InterpThrottle
                    model = obj.tabularInterpThrottle;

                case ThrottleModelEnum.Limited
                    model = obj.limitedThrottle;

                otherwise
                    error('Unknown throttle model type: %s', enum.nameStr);
            end
        end

        function setModelForEnum(obj, enum, model)
            %setModelForEnum Stores model in the slot for its type.  When the
            %stored model was the selected one, the selection follows it.
            arguments
                obj(1,1) ThrottleModelsSet
                enum(1,1) ThrottleModelEnum
                model(1,1) AbstractThrottleModel
            end

            if(model.getThrottleModelTypeEnum() ~= enum)
                error('Throttle model of type %s cannot be stored in the %s slot.', model.getThrottleModelTypeEnum().nameStr, enum.nameStr);
            end

            wasSelected = obj.selectedModel == obj.getModelForEnum(enum);

            switch enum
                case ThrottleModelEnum.PolyModel
                    obj.polyThrottle = model;

                case ThrottleModelEnum.T2WModel
                    obj.t2wThrottle = model;

                case ThrottleModelEnum.InterpThrottle
                    obj.tabularInterpThrottle = model;

                case ThrottleModelEnum.Limited
                    obj.limitedThrottle = model;

                otherwise
                    error('Unknown throttle model type: %s', enum.nameStr);
            end

            if(wasSelected)
                obj.selectedModel = model;
            end
        end

        function models = getAllModels(obj)
            %getAllModels Every stored model, in enumeration order.
            models = [obj.polyThrottle, obj.t2wThrottle, obj.tabularInterpThrottle, obj.limitedThrottle];
        end

        function useTf = openEditDialog(obj, lvdData, allowContinuity)
            out = AppDesignerGUIOutput({false});
            lvd_EditThrottleModelsSet_App(obj, lvdData, out, allowContinuity);
            useTf = out.output{1};
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            %Sets saved before the limited model existed come back holding the
            %class-level default object, which is one handle shared by every
            %such set.  Give each of them their own instance instead.
            mc = ?ThrottleModelsSet;
            prop = findobj(mc.PropertyList, 'Name', 'limitedThrottle');
            if(not(isempty(prop)) && prop.HasDefault && obj.limitedThrottle == prop.DefaultValue)
                obj.limitedThrottle = LimitedThrottleModel.getDefaultThrottleModel();
            end
        end
    end
end