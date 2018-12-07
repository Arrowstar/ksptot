classdef T2WThrottleModel < AbstractThrottleModel
    %T2WThrottleModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        targetT2W(1,1) double = 0;
    end
    
    methods
        function throttle = getThrottleAtTime(obj, ~, rVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo)
            if(obj.targetT2W <= 0)
                throttle = 0;
            else
                twRatioFH = @(throttle) T2WThrottleModel.computeTWRatio(throttle, rVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo);
                
                fullThrottleTW = twRatioFH(1.0);
                if(fullThrottleTW < obj.targetT2W)
                    throttle = 1.0;
                else
                    [x, ~, ~] = bisection(twRatioFH, 0.0 , 1.0, obj.targetT2W, 1E-5);
                    throttle = x;
                end
            end
            
            if(throttle < 0)
                throttle = 0.0;
            elseif(throttle > 1)
                throttle = 1.0;
            end
        end

        function initThrottleModel(obj, ~)
            %nothing
        end
        
        function optVar = getNewOptVar(obj)
            optVar = T2WThrottleModelOptimVar(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end
        
        function addActionTf = openEditThrottleModelUI(obj, lv)
            fakeAction = struct();
            fakeAction.throttleModel = obj;
            
            addActionTf = lvd_EditActionSetThrottleModelGUI(fakeAction, lv);
        end
    end
    
    methods(Access=private)
        function obj = T2WThrottleModel(targetT2W)
            obj.targetT2W = targetT2W;
        end     
    end
    
    methods(Static)
        function model = getDefaultThrottleModel()
            model = T2WThrottleModel(0);
        end
        
        function twRatio = computeTWRatio(throttle, rVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo)
            altitude = norm(rVect) - bodyInfo.radius;
            presskPa = getPressureAtAltitude(bodyInfo, altitude); 
            
            [~, totalThrust]= LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankMasses, stgStates, throttle, lvState, presskPa);
            
            totalMass = (dryMass + sum(tankMasses))*1000; %kg          
            totalThrust = totalThrust * 1000; % N
            
            twRatio = computeSLThrustToWeight(bodyInfo, totalThrust, totalMass);
        end
    end
end