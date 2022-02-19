classdef LaunchVehicleIntegralCalcState < AbstractLaunchVehicleCalculusState
    %LaunchVehicleIntegralCalcState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        initialTime(1,1) double = 0;
        constant(1,1) double = 0;
    end
    
    methods     
        function obj = LaunchVehicleIntegralCalcState(integralCalcObj)
            obj.calcObj = integralCalcObj;
        end
        
        function createDataFromStates(obj, stateLogEntries)
            createDataFromStates@AbstractLaunchVehicleCalculusState(obj, stateLogEntries);
            
            obj.initialTime = min(obj.gridInterp.GridVectors{1});
            obj.constant = obj.getValueAtTime(obj.initialTime);
        end
        
        function intValue = getValueAtTime(obj, time)
            intValue = integral(@(x) obj.gridInterp(x), obj.initialTime, time, 'ArrayValued',false) + obj.constant; %using arrayvalued seems to slow things down ?????
            
            if(isnan(intValue))
                error('Integral value is NaN: %s', obj.calcObj.quantStr);
            end
        end
    end
end