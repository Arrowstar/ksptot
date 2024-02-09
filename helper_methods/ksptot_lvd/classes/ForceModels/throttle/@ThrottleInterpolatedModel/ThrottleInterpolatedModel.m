classdef ThrottleInterpolatedModel < AbstractThrottleModel
    %ThrottleInterpolatedModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        t0(1,1) double = 0;
        initThrottle(1,1) double = 0;

        durations(:,1) double = 1;
        throttles(:,1) double = 0;

        interpolationType(1,1) ThrottleInterpolatedModelInterpTypeEnum = ThrottleInterpolatedModelInterpTypeEnum.Linear;
        gi
    end
    
    methods
        function throttle = getThrottleAtTime(obj, ut, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~)
            throttle = obj.gi(ut);

            if(throttle < 0)
                throttle = 0.0;
            elseif(throttle > 1)
                throttle = 1.0;
            end
        end
        
        function enum = getThrottleModelTypeEnum(~)
            enum = ThrottleModelEnum.InterpThrottle;
        end
        
        function initThrottleModel(obj, initialStateLogEntry)
            if(obj.throttleContinuity)
                throttle = initialStateLogEntry.throttle;
                obj.initThrottle = throttle;
            end

            obj.setT0(initialStateLogEntry.time);
            allTimes     = [obj.t0,           obj.t0 + cumsum(obj.durations(:)')];
            allThrottles = [obj.initThrottle, obj.throttles(:)'];
            obj.gi = griddedInterpolant(allTimes, allThrottles, obj.interpolationType.giModelTypeStr, 'nearest');
        end
        
        function setInitialThrottleFromState(obj, stateLogEntry, tOffsetDelta)
            %nothing
        end
        
        function t0 = getT0(obj)
            t0 = obj.t0;
        end
        
        function setT0(obj, newT0)
            obj.t0 = newT0;
        end
        
        function setTimeOffsets(obj, timeOffset)
            obj.throttleModel.tOffset = timeOffset;
        end
        
        function optVar = getNewOptVar(obj)
            optVar = SetInterpolatedThrottleActionOptimVar(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end

        function [addActionTf, throttleModel] = openEditThrottleModelUI(obj, lv, useContinuity)
            output = AppDesignerGUIOutput({false, obj});
            lvd_EditTabularInterpThrottleModelGUI_App(obj, lv, useContinuity, output);
            addActionTf = output.output{1};
            throttleModel = output.output{2};
        end
    end
    
    methods(Access=private)
        function obj = ThrottleInterpolatedModel()

        end     
    end
    
    methods(Static)
        function model = getDefaultThrottleModel()
            model = ThrottleInterpolatedModel();
        end
    end
end