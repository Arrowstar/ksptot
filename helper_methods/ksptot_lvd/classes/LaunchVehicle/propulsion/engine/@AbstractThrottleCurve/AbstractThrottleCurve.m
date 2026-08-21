classdef(Abstract) AbstractThrottleCurve < matlab.mixin.SetGet & matlab.mixin.Copyable
    %AbstractThrottleCurve Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        elems AbstractCurveElement
        
        constValue(1,1) double = NaN
    end
    
    properties(Transient)
        curve

        xVals double
        yVals double
    end
          
    methods        
        function addElement(obj, newElement)
            obj.elems(end+1) = newElement;
            obj.sortElems();
            obj.generateCurve();
        end
        
        function removeElement(obj, element)
            obj.elems(obj.elems == element) = [];
            obj.sortElems();
            obj.generateCurve();
        end
        
        function generateCurve(obj)
            obj.sortElems();
            
            if(length(obj.elems) > 2)
                x = [obj.elems.indepVar];
                y = [obj.elems.depVar];

                obj.xVals = x;
                obj.yVals = y;
                obj.curve = griddedInterpolant(x,y,'linear','nearest');
                
                if(all(not(diff(y))))
                    obj.constValue = y(1);
                else
                    obj.constValue = NaN;
                end
            elseif(length(obj.elems) == 2)
                x = [obj.elems.indepVar];
                y = [obj.elems.depVar];

                obj.xVals = x;
                obj.yVals = y;
                obj.curve = griddedInterpolant(x,y,'linear','nearest');
                
                if(y(1) == y(2))
                    obj.constValue = y(1);
                else
                    obj.constValue = NaN;
                end
            else
                error('Cannot generate throttle curve: the number of elements in the curve must be greater than or equal to 2.');
            end
        end
        
        function yq = evalCurve(obj, xq)            
            if(isnan(obj.constValue))
                yq = AbstractThrottleCurve.manLinInterp1D(obj.xVals, obj.yVals, xq);
            else
                yq = ones(size(xq)) * obj.constValue;
            end
        end
        
        function sortElems(obj)
            [~,I] = sort([obj.elems.indepVar], 'ascend');
            obj.elems = obj.elems(I);
        end
        
        function [x, y] = getPlotablePoints(obj)
            obj.sortElems();
            
            x = [obj.elems.indepVar];
            y = [obj.elems.depVar];
        end
    end
    
    methods(Static)
        function obj = loadobj(obj)
            obj.generateCurve();
        end
    end
    
    methods(Abstract)
        [listBoxStr, elemArr] = getListboxStr(obj)
        
        curveName = getCurveName(obj)
        
        indepVarName = getIndepVarName(obj)
        indepVarUnit = getIndepVarUnit(obj)
        depVarName = getDepVarName(obj)
        depVarUnit = getDepVarUnit(obj)
        
        newElem = createNewElement(obj)
        
        listBoxTooltipStr = getListboxTooltipStr(obj)
    end
    
    methods(Abstract, Access = protected)
        newObj = copyElement(obj)
    end
    
    methods(Static, Access = private)
        function yq = manLinInterp1D(x, y, xq)
            %manLinInterp1D Bit-exact manual 1-D linear interpolation that
            %   replicates griddedInterpolant(x, y, 'linear', 'nearest'):
            %   yq = (1-t)*y1 + t*y2 with t = (xq-x1)/(x2-x1), clamping at
            %   the grid bounds.  Verified bit-exact on real curve data.
            if(isscalar(xq))
                if(xq <= x(1))
                    yq = y(1);
                    return;
                end
                if(xq >= x(end))
                    yq = y(end);
                    return;
                end
                lo = 1; hi = length(x);
                while(hi - lo > 1)
                    mid = floor((lo+hi)/2);
                    if(xq >= x(mid)); lo = mid; else; hi = mid; end
                end
                x1 = x(lo); x2 = x(hi); y1 = y(lo); y2 = y(hi);
                t = (xq - x1)/(x2 - x1);
                yq = (1-t)*y1 + t*y2;
            else
                yq = zeros(size(xq));
                for(i=1:numel(xq))
                    yq(i) = AbstractThrottleCurve.manLinInterp1D(x, y, xq(i));
                end
            end
        end
    end
end