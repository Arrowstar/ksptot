classdef GeometricRefFrameSet < matlab.mixin.SetGet
    %GeometricRefFrameSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        refFrames(1,:) AbstractGeometricRefFrame = AbstractGeometricRefFrame.empty(1,0);
        
        lvdData LvdData
    end
    
    methods        
        function obj = GeometricRefFrameSet(lvdData)
            obj.lvdData = lvdData;
        end
        
        function addRefFrame(obj, refFrame)
            obj.refFrames(end+1) = refFrame;
        end
        
        function removeRefFrame(obj, refFrame)
            obj.refFrames([obj.refFrames] == refFrame) = [];
        end
        
        function [listBoxStr, refFrames] = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.refFrames))
                listBoxStr{end+1} = obj.refFrames(i).getListboxStr(); %#ok<AGROW>
            end
            
            refFrames = obj.refFrames;
        end
        
        function indCoordSyses = getRefFramesForInds(obj, inds)
            indCoordSyses = obj.refFrames(inds);
        end
        
        function inds = getIndsForRefFrames(obj, indRefFrames)
            inds = find(ismember(obj.refFrames, indRefFrames));
        end
        
        function indRefFrame = getRefFrameAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.refFrames))
                indRefFrame = obj.refFrames(ind);
            else
                indRefFrame = AbstractGeometricRefFrame.empty(1,0);
            end
        end
        
        function numRefFrames = getNumRefFrames(obj)
            numRefFrames = length(obj.refFrames);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            for(i=1:length(obj.refFrames))
                tf = tf || obj.refFrames(i).usesGroundObj(groundObj);
            end
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            for(i=1:length(obj.refFrames))
                tf = tf || obj.refFrames(i).usesGeometricPoint(point);
            end
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            for(i=1:length(obj.refFrames))
                tf = tf || obj.refFrames(i).usesGeometricVector(vector);
            end
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            for(i=1:length(obj.refFrames))
                tf = tf || obj.refFrames(i).usesGeometricCoordSys(coordSys);
            end
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            for(i=1:length(obj.refFrames))
                tf = tf || obj.refFrames(i).usesGeometricRefFrame(refFrame);
            end
        end
    end
end