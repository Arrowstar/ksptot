classdef IspPressureCurve < AbstractThrottleCurve
    %IspPressureCurve Summary of this class goes here
    %   Detailed explanation goes here
       
    methods(Access=private)
        function obj = IspPressureCurve()
            element0 = IspPressureCurveElement(LaunchVehicleEngine.vacPress,    350);
            element1 = IspPressureCurveElement(LaunchVehicleEngine.seaLvlPress, 250);
            
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
                listBoxStr{i} = sprintf('Press = %.3f kPa, Isp = %.3f sec', obj.elems(i).indepVar, obj.elems(i).depVar);
            end
            
            elemArr = obj.elems;
        end
        
        function curveName = getCurveName(obj)
            curveName = 'Base Isp/Pressure Curve';
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
        
        function newElem = createNewElement(obj)
            newElem = IspPressureCurveElement(0,1);
        end
        
        function listBoxTooltipStr = getListboxTooltipStr(obj)
            listBoxTooltipStr = 'Elements of the specific impulse curve profile.  There must be a point at 0 kPa and 101.325 kPa, and those elements cannot have their pressure value edited.';
        end
    end
    
    methods(Access = protected)
        function newObj = copyElement(obj)
            newObj = IspPressureCurve();
            
            for(i=1:length(obj.elems))
                newObj.elems(i) = obj.elems(i).copy();
            end
            
            newObj.generateCurve();
        end
    end
    
    methods(Static)
        function defaultCurve = getDefaultIspPressureCurve()
            defaultCurve = IspPressureCurve();
        end
        
        function curve = getCurveFromPoints(pressPts, ispPts)
            curve = IspPressureCurve();
            curve.elems = IspPressureCurveElement.empty(1,0);
            
            for(i=1:length(pressPts))
                curve.elems(end+1) = IspPressureCurveElement(pressPts(i), ispPts(i));
            end
        end
    end
end