classdef ThrottlePolyModel < AbstractThrottleModel
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        throttleModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
    end
    
    methods
        function throttle = getThrottleAtTime(obj,ut)
            throttle = obj.throttleModel.getValueAtTime(ut);
            
            if(throttle < 0)
                throttle = 0.0;
            elseif(throttle > 1)
                throttle = 1.0;
            end
        end
    end
    
    methods(Access=private)
        function obj = ThrottlePolyModel(throttleModel)
            obj.throttleModel = throttleModel;
        end     
    end
    
    methods(Static)
        function model = getDefaultThrottleModel()
            throttlePoly = PolynominalModel(0,1,0,0);
            model = ThrottlePolyModel(throttlePoly);
        end
    end
end