classdef(Abstract) AbstractThrottleCurve < matlab.mixin.SetGet & matlab.mixin.Copyable
    %AbstractThrottleCurve Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        elems AbstractCurveElement
        
        constValue(1,1) double = NaN
    end
    
    properties(Transient)
        curve
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

%                 xc = [max(x)];
%                 yc = [0];
%                 cc = [0;1];
%                 con = struct('xc',xc,'cc',cc,'yc',yc);
%                 obj.curve = splinefit(x,y,x,2); %I set things to use a piecewise linear interpolation now. 2020/12/18
                obj.curve = griddedInterpolant(x,y,'linear','nearest');
                
                if(all(not(diff(y))))
                    obj.constValue = y(1);
                else
                    obj.constValue = NaN;
                end
            elseif(length(obj.elems) == 2)
                x = [obj.elems.indepVar];
                y = [obj.elems.depVar];

%                 obj.curve = splinefit(x,y,1,2);
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
%                 if(isempty(obj.curve))
%                     obj.generateCurve();
%                 end
                
                yq = obj.curve(xq);
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
end