classdef FuelThrottleCurveElement < AbstractCurveElement
    %FuelThrottleCurveElement Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        minIndepValue = 0;
        maxIndepValue = 100;
        
        minDepValue = 0;
        maxDepValue = 1;
        
        mandatoryIndepValues = [0, 100];
    end
    
    methods
        function obj = FuelThrottleCurveElement(fuelRemainPct, throttleModifier)
            obj.indepVar = fuelRemainPct;
            obj.depVar = throttleModifier;
        end
        
        function indepVarName = getIndepVarName(obj)
            indepVarName = 'Fuel Remaining';
        end
        
        function indepVarUnit = getIndepVarUnit(obj)
            indepVarUnit = '%';
        end
        
        function depVarName = getDepVarName(obj)
            depVarName = 'Throttle Modifier';
        end
        
        function depVarUnit = getDepVarUnit(obj)
            depVarUnit = '';
        end
    end
end