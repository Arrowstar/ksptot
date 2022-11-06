classdef ThrustPressureCurve < AbstractThrottleCurve
    %ThrustPressureCurve Summary of this class goes here
    %   Detailed explanation goes here
       
    methods(Access=private)
        function obj = ThrustPressureCurve()
            element0 = ThrustPressureCurveElement(LaunchVehicleEngine.vacPress,    215);
            element1 = ThrustPressureCurveElement(LaunchVehicleEngine.seaLvlPress, 168);
            
            obj.elems(end+1) = element0;
            obj.elems(end+1) = element1;
            
            obj.sortElems();
            obj.generateCurve();
        end
    end
    
    methods                        
        function [listBoxStr, elemArr] = getListboxStr(obj)
            obj.sortElems();
            
            listBoxStr = cell(length(obj.elems),1);
            for(i=1:length(obj.elems))
                listBoxStr{i} = sprintf('Press = %.3f kPa, Thrust = %.3f kN', obj.elems(i).indepVar, obj.elems(i).depVar);
            end
            
            elemArr = obj.elems;
        end
        
        function curveName = getCurveName(obj)
            curveName = 'Base Thrust/Pressure Curve';
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
        
        function newElem = createNewElement(obj)
            newElem = ThrustPressureCurveElement(0,1);
        end
        
        function listBoxTooltipStr = getListboxTooltipStr(obj)
            listBoxTooltipStr = 'Elements of the thrust curve profile.  There must be a point at 0 kPa and 101.325 kPa, and those elements cannot have their pressure value edited.';
        end
    end
    
    methods(Access = protected)
        function newObj = copyElement(obj)
            newObj = ThrustPressureCurve();
            
            for(i=1:length(obj.elems))
                newObj.elems(i) = obj.elems(i).copy();
            end
            
            newObj.generateCurve();
        end
    end
    
    methods(Static)
        function defaultCurve = getDefaultThrustPressureCurve()
            defaultCurve = ThrustPressureCurve();
        end
        
        function curve = getCurveFromPoints(pressPts, thrustPts)
            curve = ThrustPressureCurve();
            curve.elems = ThrustPressureCurveElement.empty(1,0);
            
            for(i=1:length(pressPts))
                curve.elems(end+1) = ThrustPressureCurveElement(pressPts(i), thrustPts(i));
            end
            
            curve.generateCurve();
        end
    end
end