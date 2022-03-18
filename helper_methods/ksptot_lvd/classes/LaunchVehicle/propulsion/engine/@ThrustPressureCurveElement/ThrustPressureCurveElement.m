classdef ThrustPressureCurveElement < AbstractCurveElement
    %ThrustPressureCurveElement Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        minIndepValue = 0;
        maxIndepValue = NaN;
        
        minDepValue = 0;
        maxDepValue = NaN;
        
        mandatoryIndepValues = [LaunchVehicleEngine.vacPress, LaunchVehicleEngine.seaLvlPress];
    end
    
    methods
        function obj = ThrustPressureCurveElement(atmoPress, engineThrust)
            obj.indepVar = atmoPress;
            obj.depVar = engineThrust;
        end
        
        function indepVarName = getIndepVarName(obj)
            indepVarName = 'Atmospheric Pressure';
        end
        
        function indepVarUnit = getIndepVarUnit(obj)
            indepVarUnit = 'kPa';
        end
        
        function depVarName = getDepVarName(obj)
            depVarName = 'Thrust';
        end
        
        function depVarUnit = getDepVarUnit(obj)
            depVarUnit = 'kN';
        end
    end
end