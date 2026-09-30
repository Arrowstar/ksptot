classdef SelectableThrottleModel < AbstractThrottleModel
    %SelectableThrottleModel Throttle law with a selectable math model.
    %
    %   Throttle parity with GenericSelectableSteeringModel (B1): the
    %   throttle is a time-only function drawn from one of three selectable
    %   steering math models -- a sum of polynomial terms, a sum of sines,
    %   or a linear tangent -- reused directly since they are already pure
    %   functions of time.  The FitNet branch is deliberately NOT offered
    %   (a neural net adds nothing to a scalar throttle program that the
    %   other three cannot fit).
    %
    %   Unlike steering angles, throttle is clamped to [0, 1].

    properties
        %Selected math model type.  Only the non-FitNet members of
        %SteerMathModelTypeEnum are valid here; FitNet is rejected in the
        %setter below.
        selModel(1,1) SteerMathModelTypeEnum = SteerMathModelTypeEnum.GenericPoly

        %Stored math models, one per selectable type.  Switching selModel
        %never discards the other branches' configuration.
        polyModel(1,1) SumOfPolyTermsModel = SumOfPolyTermsModel(0);
        sinesModel(1,1) SumOfSinesModel = SumOfSinesModel(0);
        linTanModel(1,1) LinearTangentSelectableModel = LinearTangentSelectableModel(0,0,0,0,0);
    end

    properties(Dependent)
        throttleMathModel(1,1) AbstractSteeringMathModel
    end

    methods
        function model = get.throttleMathModel(obj)
            switch obj.selModel
                case SteerMathModelTypeEnum.GenericPoly
                    model = obj.polyModel;

                case SteerMathModelTypeEnum.SumOfSines
                    model = obj.sinesModel;

                case SteerMathModelTypeEnum.LinearTangent
                    model = obj.linTanModel;

                otherwise
                    error('SelectableThrottleModel:unknownMathModel', 'Unknown throttle math model: %s', obj.selModel.name);
            end
        end

        function set.throttleMathModel(obj, newModel)
            switch class(newModel)
                case 'SumOfPolyTermsModel'
                    obj.polyModel = newModel;

                case 'SumOfSinesModel'
                    obj.sinesModel = newModel;

                case 'LinearTangentSelectableModel'
                    obj.linTanModel = newModel;

                otherwise
                    error('SelectableThrottleModel:unknownMathModelClass', 'Unknown throttle math model class: %s', class(newModel));
            end
        end

        function set.selModel(obj, newSelModel)
            if(newSelModel == SteerMathModelTypeEnum.FitNet)
                error('SelectableThrottleModel:fitNetNotSupported', 'The FitNet math model is not supported for throttle.');
            end

            obj.selModel = newSelModel;
        end

        function throttle = getThrottleAtTime(obj, ut, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~)
            throttle = obj.throttleMathModel.getValueAtTime(ut);

            if(throttle < 0)
                throttle = 0.0;
            elseif(throttle > 1)
                throttle = 1.0;
            end
        end

        function enum = getThrottleModelTypeEnum(~)
            enum = ThrottleModelEnum.Selectable;
        end

        function initThrottleModel(obj, initialStateLogEntry)
            t0 = initialStateLogEntry.time;
            obj.setT0(t0);

            if(obj.throttleContinuity)
                throttle = initialStateLogEntry.throttle;
                obj.throttleMathModel.setConstValueForContinuity(throttle);
            end
        end

        function setInitialThrottleFromState(obj, stateLogEntry, tOffsetDelta)
            t0 = stateLogEntry.time;
            obj.setT0(t0);

            obj.throttleMathModel.setTimeOffset(obj.throttleMathModel.getTimeOffset() + tOffsetDelta);
        end

        function t0 = getT0(obj)
            t0 = obj.throttleMathModel.getT0();
        end

        function setT0(obj, newT0)
            obj.polyModel.setT0(newT0);
            obj.sinesModel.setT0(newT0);
            obj.linTanModel.setT0(newT0);
        end

        function setTimeOffsets(obj, timeOffset)
            obj.polyModel.setTimeOffset(timeOffset);
            obj.sinesModel.setTimeOffset(timeOffset);
            obj.linTanModel.setTimeOffset(timeOffset);
        end

        function timeOffset = getTimeOffsets(obj)
            timeOffset = obj.throttleMathModel.getTimeOffset();
        end

        function optVar = getNewOptVar(obj)
            optVar = SetSelectableThrottleModelActionOptimVar(obj);
        end

        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end

        function newModel = deepCopy(obj)
            %deepCopy Copies every stored branch plus the selector.  A
            %constructor-only copy would silently revert the unselected
            %branches to their defaults (the GenericSelectableSteeringModel
            %precedent), so each slot is copied explicitly.
            newModel = SelectableThrottleModel();

            newModel.polyModel = obj.polyModel.deepCopy();
            newModel.sinesModel = obj.sinesModel.deepCopy();
            newModel.linTanModel = obj.linTanModel.deepCopy();

            newModel.selModel = obj.selModel;
            newModel.throttleContinuity = obj.throttleContinuity;
        end

        function [addActionTf, throttleModel] = openEditThrottleModelUI(obj, lv, useContinuity)
            output = AppDesignerGUIOutput({false, obj});
            lvd_EditSelectableThrottleModelGUI_App(obj, lv, useContinuity, output);
            addActionTf = output.output{1};
            throttleModel = output.output{2};
        end
    end

    methods(Access=private)
        function obj = SelectableThrottleModel()
            %Fresh math-model handles per instance: property default
            %expressions are evaluated once at class load, so leaving the
            %slots on their defaults would share one handle across every
            %model.
            obj.polyModel = SumOfPolyTermsModel(0);
            obj.sinesModel = SumOfSinesModel(0);
            obj.linTanModel = LinearTangentSelectableModel(0,0,0,0,0);
        end
    end

    methods(Static)
        function model = getDefaultThrottleModel()
            model = SelectableThrottleModel();
        end
    end
end
