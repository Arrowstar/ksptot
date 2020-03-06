classdef GriddedInterpolantPointSet < matlab.mixin.SetGet
    %GriddedInterpolantPointSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        points(1,:) GriddedInterpolantPoint
    end
    
    methods
        function obj = GriddedInterpolantPointSet()

        end
        
        function [newInd] = addPoint(obj, newPt)
            obj.points(end+1) = newPt;
            
            obj.sortPoints();
            newInd = find(obj.points == newPt,1,'first');
        end
        
        function removePoint(obj, point)
            obj.points(obj.points == point) = [];
        end
        
        function point = getPointByIndex(obj, ind)
            point = GriddedInterpolantPoint.empty(1,0);
            
            if(ind >= 1 && ind <= length(obj.points))
                point = obj.points(ind);
            end
        end
        
        function numPts = getNumPoints(obj)
            numPts = length(obj.points);
        end
        
        function sortedPts = sortPoints(obj)
            [~, ind] = sort([obj.points.x]);
            sortedPts = obj.points(ind);
            
            obj.points = sortedPts;
        end
        
        function str = getListboxStr(obj)
            sortedPts = obj.sortPoints();
            
            str = {};
            for(i=1:length(sortedPts))
                str{i} = sortedPts(i).getListboxStr(); %#ok<AGROW>
            end
        end
        
        function gI = getGriddedInterpFromPoints(obj, method, extrapolationMethod)
            sortedPts = obj.sortPoints();
            
            x = [sortedPts.x];
            v = [sortedPts.v];
            
            gI = griddedInterpolant(x,v, method.methodStr, extrapolationMethod.methodStr);
        end
        
        function [x, v] = getPointVectors(obj)
            x = [obj.points.x];
            v = [obj.points.v];
        end
    end
end