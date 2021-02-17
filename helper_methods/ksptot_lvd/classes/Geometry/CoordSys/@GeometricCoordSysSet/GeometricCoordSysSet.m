classdef GeometricCoordSysSet < matlab.mixin.SetGet
    %GeometricCoordSysSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        coordSyses(1,:) AbstractGeometricCoordSystem
        
        lvdData LvdData
    end
    
    methods        
        function obj = GeometricCoordSysSet(lvdData)
            obj.lvdData = lvdData;
        end
        
        function addCoordSys(obj, coordSys)
            obj.coordSyses(end+1) = coordSys;
        end
        
        function removeCoordSys(obj, coordSys)
            obj.coordSyses([obj.coordSyses] == coordSys) = [];
        end
        
        function [listBoxStr, coordSyses] = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.coordSyses))
                listBoxStr{end+1} = obj.coordSyses(i).getListboxStr(); %#ok<AGROW>
            end
            
            coordSyses = obj.coordSyses;
        end
        
        function indCoordSyses = getCoordSysesForInds(obj, inds)
            indCoordSyses = obj.coordSyses(inds);
        end
        
        function inds = getIndsForCoordSyses(obj, indCoordSyses)
            inds = find(ismember(obj.coordSyses, indCoordSyses));
        end
        
        function indCoordSys = getCoordSysAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.coordSyses))
                indCoordSys = obj.coordSyses(ind);
            else
                indCoordSys = AbstractGeometricCoordSystem.empty(1,0);
            end
        end
        
        function numCoordSyses = getNumCoordSyses(obj)
            numCoordSyses = length(obj.coordSyses);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            for(i=1:length(obj.coordSyses))
                tf = tf || obj.coordSyses(i).usesGroundObj(groundObj);
            end
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            for(i=1:length(obj.coordSyses))
                tf = tf || obj.coordSyses(i).usesGeometricPoint(point);
            end
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            for(i=1:length(obj.coordSyses))
                tf = tf || obj.coordSyses(i).usesGeometricVector(vector);
            end
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            for(i=1:length(obj.coordSyses))
                tf = tf || obj.coordSyses(i).usesGeometricCoordSys(coordSys);
            end
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            for(i=1:length(obj.coordSyses))
                tf = tf || obj.coordSyses(i).usesGeometricRefFrame(refFrame);
            end
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = false;
            for(i=1:length(obj.coordSyses))
                tf = tf || obj.coordSyses(i).usesGeometricAngle(angle);
            end
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = false;
            for(i=1:length(obj.coordSyses))
                tf = tf || obj.coordSyses(i).usesGeometricPlane(plane);
            end
        end
    end
end