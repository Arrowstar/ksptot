classdef FuelThrottleCurve < AbstractThrottleCurve
    %FuelThrottleCurve Summary of this class goes here
    %   Detailed explanation goes here
       
    methods(Access=private)
        function obj = FuelThrottleCurve()
            element0 = FuelThrottleCurveElement(0,1);
            element1 = FuelThrottleCurveElement(100,1);
            
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
                listBoxStr{i} = sprintf('Fuel = %.3f%%, Thr = %.3f', obj.elems(i).indepVar, obj.elems(i).depVar);
            end
            
            elemArr = obj.elems;
        end
        
        function curveName = getCurveName(obj)
            curveName = 'Fuel Remaining Throttle Curve';
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
        
        function newElem = createNewElement(obj)
            newElem = FuelThrottleCurveElement(50,1);
        end
        
        function listBoxTooltipStr = getListboxTooltipStr(obj)
            listBoxTooltipStr = 'Elements of the throttle modifer profile.  There must be a point at 0% and 100% fuel remaining, and those elements cannot have their fuel remaining value edited.';
        end
    end
    
    methods(Access = protected)
        function newObj = copyElement(obj)
            newObj = FuelThrottleCurve;
            
            for(i=1:length(obj.elems))
                newObj.elems(i) = obj.elems(i).copy();
            end
            
            newObj.generateCurve();
        end
    end
    
    methods(Static)
        function defaultCurve = getDefaultFuelThrottleCurve()
            defaultCurve = FuelThrottleCurve();
        end
    end
end