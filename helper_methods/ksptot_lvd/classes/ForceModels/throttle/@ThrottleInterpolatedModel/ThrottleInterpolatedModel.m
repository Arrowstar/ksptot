classdef ThrottleInterpolatedModel < AbstractThrottleModel
    %ThrottleInterpolatedModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        t0(1,1) double = 0;
        initThrottle(1,1) double = 0;

        durations(:,1) double = 1;
        throttles(:,1) double = 0;

        %Time offset with the same meaning as PolynominalModel.tOffset: the
        %table is evaluated at (ut - t0) + tOffset.  Zero by default.
        tOffset(1,1) double = 0;

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
            tableStart   = obj.t0 - obj.tOffset; %table time = (ut - t0) + tOffset
            allTimes     = [tableStart,       tableStart + cumsum(obj.durations(:)')];
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
            %setTimeOffsets Same contract as ThrottlePolyModel: shifts the
            %time argument the table is evaluated at.  Takes effect on the next
            %initThrottleModel call, which rebuilds the interpolant.
            obj.tOffset = timeOffset;
        end

        function timeOffset = getTimeOffsets(obj)
            timeOffset = obj.tOffset;
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