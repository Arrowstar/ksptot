classdef ThrottlePolyModel < AbstractThrottleModel
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        throttleModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
    end
    
    methods
        function throttle = getThrottleAtTime(obj, ut, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~)
            throttle = obj.throttleModel.getValueAtTime(ut);
            
            if(throttle < 0)
                throttle = 0.0;
            elseif(throttle > 1)
                throttle = 1.0;
            end
        end
        
        function enum = getThrottleModelTypeEnum(~)
            enum = ThrottleModelEnum.PolyModel;
        end
        
        function initThrottleModel(obj, initialStateLogEntry)
            t0 = initialStateLogEntry.time;
            throttle = initialStateLogEntry.throttle;
            
            obj.setT0(t0)
            
            if(obj.throttleContinuity)
                obj.throttleModel.constTerm = throttle;
            end
        end
        
        function setT0(obj, newT0)
            obj.throttleModel.t0 = newT0;
        end
        
        function setPolyTerms(obj, const, linear, accel)
            obj.throttleModel.constTerm = const;
            obj.throttleModel.linearTerm = linear;
            obj.throttleModel.accelTerm = accel;
        end

        function optVar = getNewOptVar(obj)
            optVar = SetPolyThrottleModelActionOptimVar(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end
    end
    
    methods(Access=private)
        function obj = ThrottlePolyModel(throttleModel)
            obj.throttleModel = throttleModel;
        end     
    end
    
    methods(Static)
        function model = getDefaultThrottleModel()
            throttlePoly = PolynominalModel(0,0,0,0);
            model = ThrottlePolyModel(throttlePoly);
        end
    end
end