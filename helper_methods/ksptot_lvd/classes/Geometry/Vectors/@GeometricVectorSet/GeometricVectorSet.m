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
            inds = find(ismember(obj.vectors, indVectors));
        end
        
        function indVector = getVectorAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.vectors))
                indVector = obj.vectors(ind);
            else
                indVector = AbstractGeometricVector.empty(1,0);
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
        
        function tf = usesGeometricAngle(obj, angle)
            tf = false;
            for(i=1:length(obj.vectors))
                tf = tf || obj.vectors(i).usesGeometricAngle(angle);
            end
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = false;
            for(i=1:length(obj.vectors))
                tf = tf || obj.vectors(i).usesGeometricPlane(plane);
            end
        end
        
        %%% Graphical Analysis Task String methods %%%
        function vectGAStr = getAllVectorGraphAnalysisTaskStrs(obj)
            vectGAStr = horzcat(obj.getVectorXComponentGraphAnalysisTaskStrs(), ...
                                obj.getVectorYComponentGraphAnalysisTaskStrs(), ... 
                                obj.getVectorZComponentGraphAnalysisTaskStrs(), ...
                                obj.getVectorMagComponentGraphAnalysisTaskStrs(), ...
                                obj.getOriginPosXComponentGraphAnalysisTaskStrs(), ...
                                obj.getOriginPosYComponentGraphAnalysisTaskStrs(), ...
                                obj.getOriginPosZComponentGraphAnalysisTaskStrs());
        end
        
        function [vectXGAStr, vectors] = getVectorXComponentGraphAnalysisTaskStrs(obj)
            vectors = obj.vectors;
            
            vectXGAStr = cell(1,length(vectors));
            A = length(vectors);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(vectors))
                vectXGAStr{i} = sprintf(sprintf('Vector %s X Component - "%s"',formSpec, vectors(i).getName()), i);
            end
        end
        
        function [vectYGAStr, vectors] = getVectorYComponentGraphAnalysisTaskStrs(obj)
            vectors = obj.vectors;
            
            vectYGAStr = cell(1,length(vectors));
            A = length(vectors);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(vectors))
                vectYGAStr{i} = sprintf(sprintf('Vector %s Y Component - "%s"',formSpec, vectors(i).getName()), i);
            end
        end
        
        function [vectZGAStr, vectors] = getVectorZComponentGraphAnalysisTaskStrs(obj)
            vectors = obj.vectors;
            
            vectZGAStr = cell(1,length(vectors));
            A = length(vectors);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(vectors))
                vectZGAStr{i} = sprintf(sprintf('Vector %s Z Component - "%s"',formSpec, vectors(i).getName()), i);
            end
        end
        
        function [vectMagGAStr, vectors] = getVectorMagComponentGraphAnalysisTaskStrs(obj)
            vectors = obj.vectors;
            
            vectMagGAStr = cell(1,length(vectors));
            A = length(vectors);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(vectors))
                vectMagGAStr{i} = sprintf(sprintf('Vector %s Magnitude - "%s"',formSpec, vectors(i).getName()), i);
            end
        end
        
        function [originPosXGAStr, vectors] = getOriginPosXComponentGraphAnalysisTaskStrs(obj)
            vectors = obj.vectors;
            
            originPosXGAStr = cell(1,length(vectors));
            A = length(vectors);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(vectors))
                originPosXGAStr{i} = sprintf(sprintf('Vector %s Origin Position (X) - "%s"',formSpec, vectors(i).getName()), i);
            end
        end
        
        function [originPosYGAStr, vectors] = getOriginPosYComponentGraphAnalysisTaskStrs(obj)
            vectors = obj.vectors;
            
            originPosYGAStr = cell(1,length(vectors));
            A = length(vectors);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(vectors))
                originPosYGAStr{i} = sprintf(sprintf('Vector %s Origin Position (Y) - "%s"',formSpec, vectors(i).getName()), i);
            end
        end
        
        function [originPosZGAStr, vectors] = getOriginPosZComponentGraphAnalysisTaskStrs(obj)
            vectors = obj.vectors;
            
            originPosZGAStr = cell(1,length(vectors));
            A = length(vectors);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(vectors))
                originPosZGAStr{i} = sprintf(sprintf('Vector %s Origin Position (Z) - "%s"',formSpec, vectors(i).getName()), i);
            end
        end
    end
end