classdef FuelThrottleCurve < matlab.mixin.SetGet & matlab.mixin.Copyable
    %FuelThrottleCurve Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        elems(1,:) FuelThrottleCurveElement
        curve struct
    end
    
    methods(Access=private)
        function obj = FuelThrottleCurve()
            element0 = FuelThrottleCurveElement(0,1);
            element1 = FuelThrottleCurveElement(1,1);
            
            obj.elems(end+1) = element0;
            obj.elems(end+1) = element1;
            
            obj.sortElems();
            obj.generateCurve();
        end
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
            if(length(obj.elems) > 2)
                x = [obj.elems.fuelRemainPct];
                y = [obj.elems.throttleModifier];

                xc = [max(x)];
                yc = [0];
                cc = [0;1];
                con = struct('xc',xc,'cc',cc,'yc',yc);
                obj.curve = splinefit(x,y,x,con);
                
%                 obj.curve = @(xq) spline(x,y,xq);
            elseif(length(obj.elems) == 2)
                x = [obj.elems.fuelRemainPct];
                y = [obj.elems.throttleModifier];

                obj.curve = splinefit(x,y,1,2);
            else
                error('Cannot generate fuel throttle curve: the number of elements in the curve must be greater than or equal to 2.');
            end
        end
        
        function yq = evalCurve(obj, xq)
%             yq = obj.curve(xq);
            yq = ppval(obj.curve,xq);
        end
        
        function [listBoxStr, elemArr] = getListboxStr(obj)
            obj.sortElems();
            
            listBoxStr = cell(length(obj.elems),1);
            for(i=1:length(obj.elems))
                listBoxStr{i} = sprintf('Fuel = %.3f%%, Thr = %.3f', 100*obj.elems(i).fuelRemainPct, obj.elems(i).throttleModifier);
            end
            
            elemArr = obj.elems;
        end
        
        function sortElems(obj)
            [~,I] = sort([obj.elems.fuelRemainPct], 'descend');
            obj.elems = obj.elems(I);
        end
        
        function [x, y] = getPlotablePoints(obj)
            obj.sortElems();
            
            x = 100*[obj.elems.fuelRemainPct];
            y = [obj.elems.throttleModifier];
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