classdef T2WThrottleModel < AbstractThrottleModel
    %T2WThrottleModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        targetT2W(1,1) double = 0;
    end
    
    methods
        function throttle = getThrottleAtTime(obj, ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates)
            if(obj.targetT2W <= 0)
                throttle = 0;
            else
                twRatioFH = @(throttle) computeTWRatio(throttle, ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);
                
                fullThrottleTW = twRatioFH(1.0);
                if(fullThrottleTW < obj.targetT2W)
                    throttle = 1.0;
                else
%                     [x, ~, ~] = bisection(twRatioFH, 0.0 , 1.0, obj.targetT2W, 1E-5);
                    x = fzero(@(x) twRatioFH(x) - obj.targetT2W, 0.5, optimset('TolX',1E-8));

                    throttle = x;
                end
            end
            
            if(throttle < 0)
                throttle = 0.0;
            elseif(throttle > 1)
                throttle = 1.0;
            end
        end

        function initThrottleModel(obj, initialStateLogEntry)            
            if(obj.throttleContinuity)
                throttle = initialStateLogEntry.throttle;

                tankStates = initialStateLogEntry.getAllActiveTankStates();

                tankMasses = zeros(size(tankStates));
                for(i=1:length(tankStates))
                    tankMasses(i) = tankStates(i).tankMass;
                end
                
                powerStorageStates = initialStateLogEntry.getAllActivePwrStorageStates();
                storageSoCs = NaN(size(powerStorageStates));
                for(i=1:length(powerStorageStates))
                    storageSoCs(i) = powerStorageStates(i).getStateOfCharge();
                end

                obj.targetT2W = computeTWRatio(throttle, initialStateLogEntry.time, initialStateLogEntry.position, initialStateLogEntry.velocity, tankMasses, initialStateLogEntry.getTotalVehicleDryMass(), ...
                                               initialStateLogEntry.stageStates, initialStateLogEntry.lvState, tankStates, initialStateLogEntry.centralBody, ...
                                               storageSoCs, powerStorageStates);
            end
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
    end
end