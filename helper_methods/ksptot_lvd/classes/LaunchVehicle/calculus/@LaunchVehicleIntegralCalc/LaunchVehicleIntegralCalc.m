classdef LaunchVehicleIntegralCalc < AbstractLaunchVehicleCalculusCalc
    %LaunchVehicleIntegralCalc Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        type(1,1) CalculusCalculationEnum = CalculusCalculationEnum.Integral;
    end
    
    methods
        function obj = LaunchVehicleIntegralCalc(lvdData)
            obj.lvdData = lvdData;
            
            obj.id = rand();
        end
        
        function nameStr = getNameStr(obj)
            nameStr = sprintf('%s Integral', obj.quantStr);
        end
        
        function initState = createInitialState(obj)
            initState = LaunchVehicleIntegralCalcState(obj);
        end
    end
end