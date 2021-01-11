classdef GeometricPointSet < matlab.mixin.SetGet
    %GeometricPointSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        points(1,:) AbstractGeometricPoint
        
        lvdData LvdData
    end
    
    methods        
        function obj = GeometricPointSet(lvdData)
            obj.lvdData = lvdData;
        end
        
        function addPoint(obj, point)
            obj.points(end+1) = point;
        end
        
        function removePoint(obj, point)
            obj.points([obj.points] == point) = [];
        end
        
        function listBoxStr = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.points))
                listBoxStr{end+1} = obj.points(i).getListboxStr(); %#ok<AGROW>
            end
        end
        
        function indPoints = getPointsForInds(obj, inds)
            indPoints = obj.points(inds);
        end
        
        function inds = getIndsForPoints(obj, indPoints)
            inds = [];
            for(i=1:length(indPoints))
                for(j=1:length(obj.points))
                    if(indPoints(i) == obj.points(j))
                        inds(end+1) = j; %#ok<AGROW>
                        break;
                    end
                end
            end
        end
        
        function indPoint = getPointAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.points))
                indPoint = obj.points(ind);
            else
                indPoint = AbstractGeometricPoint.empty(1,0);
            end
        end
        
        function numPoints = getNumPoints(obj)
            numPoints = length(obj.points);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            for(i=1:length(obj.points))
                tf = tf || obj.points(i).usesGroundObj(groundObj);
            end
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            for(i=1:length(obj.points))
                tf = tf || obj.points(i).usesGeometricPoint(point);
            end
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            for(i=1:length(obj.points))
                tf = tf || obj.points(i).usesGeometricVector(vector);
            end
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            for(i=1:length(obj.points))
                tf = tf || obj.points(i).usesGeometricCoordSys(coordSys);
            end
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            for(i=1:length(obj.points))
                tf = tf || obj.points(i).usesGeometricRefFrame(refFrame);
            end
        end
    end
end