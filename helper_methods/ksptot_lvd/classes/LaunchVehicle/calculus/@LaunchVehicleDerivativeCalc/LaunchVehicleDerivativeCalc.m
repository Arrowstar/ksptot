classdef LaunchVehicleDerivativeCalc < AbstractLaunchVehicleCalculusCalc
    %LaunchVehicleDerivativeCalc Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        type(1,1) CalculusCalculationEnum = CalculusCalculationEnum.Derivative
    end
    
    methods
        function obj = LaunchVehicleDerivativeCalc(lvdData)
            obj.lvdData = lvdData;
            
            obj.id = rand();
        end
        
        function nameStr = getNameStr(obj)
            nameStr = sprintf('%s Derivative', obj.quantStr);
        end
        
        function initState = createInitialState(obj)
            initState = LaunchVehicleDerivativeCalcState(obj);
        end
        
%         tf = isInUse(obj);
    end
end