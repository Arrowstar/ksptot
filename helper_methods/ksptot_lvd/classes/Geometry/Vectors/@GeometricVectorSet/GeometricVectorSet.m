classdef GeometricVectorSet < matlab.mixin.SetGet
    %GeometricVectorSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        vectors(1,:) AbstractGeometricVector
        
        lvdData LvdData
    end
    
    methods        
        function obj = GeometricVectorSet(lvdData)
            obj.lvdData = lvdData;
        end
        
        function addVector(obj, vector)
            obj.vectors(end+1) = vector;
        end
        
        function removeVector(obj, vector)
            obj.vectors([obj.vectors] == vector) = [];
        end
        
        function [listBoxStr, vectors] = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.vectors))
                listBoxStr{end+1} = obj.vectors(i).getListboxStr(); %#ok<AGROW>
            end
            
            vectors = obj.vectors;
        end
        
        function indVectors = getVectorsForInds(obj, inds)
            indVectors = obj.vectors(inds);
        end
        
        function inds = getIndsForVectors(obj, indVectors)
%             inds = find(ismember(obj.vectors, indVectors));
            inds = [];
            for(i=1:length(indVectors))
                for(j=1:length(obj.vectors))
                    if(indVectors(i) == obj.vectors(j))
                        inds(end+1) = j; %#ok<AGROW>
                        break;
                    end
                end
            end
        end
        
        function indPoint = getVectorAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.vectors))
                indPoint = obj.vectors(ind);
            else
                indPoint = AbstractGeometricVector.empty(1,0);
            end
        end
        
        function numVectors = getNumVectors(obj)
            numVectors = length(obj.vectors);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            for(i=1:length(obj.vectors))
                tf = tf || obj.vectors(i).usesGroundObj(groundObj);
            end
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            for(i=1:length(obj.vectors))
                tf = tf || obj.vectors(i).usesGeometricPoint(point);
            end
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            for(i=1:length(obj.vectors))
                tf = tf || obj.vectors(i).usesGeometricVector(vector);
            end
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            for(i=1:length(obj.vectors))
                tf = tf || obj.vectors(i).usesGeometricCoordSys(coordSys);
            end
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            for(i=1:length(obj.vectors))
                tf = tf || obj.vectors(i).usesGeometricRefFrame(refFrame);
            end
        end
    end
end