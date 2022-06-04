classdef IspPressureCurveElement < AbstractCurveElement
    %IspPressureCurveElement Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        minIndepValue = 0;
        maxIndepValue = NaN;
        
        minDepValue = 1E-6;
        maxDepValue = NaN;
        
        mandatoryIndepValues = [LaunchVehicleEngine.vacPress, LaunchVehicleEngine.seaLvlPress];
    end
    
    methods
        function obj = IspPressureCurveElement(atmoPress, engineIsp)
            obj.indepVar = atmoPress;
            obj.depVar = engineIsp;
        end
        
        function indepVarName = getIndepVarName(obj)
            indepVarName = 'Atmospheric Pressure';
        end
        
        function indepVarUnit = getIndepVarUnit(obj)
            indepVarUnit = 'kPa';
        end
        
        function depVarName = getDepVarName(obj)
            depVarName = 'Isp';
        end
        
        function depVarUnit = getDepVarUnit(obj)
            depVarUnit = 'sec';
        end
    end
end