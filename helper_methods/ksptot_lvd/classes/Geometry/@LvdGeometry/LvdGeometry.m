classdef LvdGeometry < matlab.mixin.SetGet
    %LvdGeometry Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        points GeometricPointSet = GeometricPointSet.empty(1,0)
        vectors GeometricVectorSet = GeometricVectorSet.empty(1,0)
        coordSyses GeometricCoordSysSet = GeometricCoordSysSet.empty(1,0)
        refFrames GeometricRefFrameSet = GeometricRefFrameSet.empty(1,0)
        
        lvdData LvdData
    end
    
    methods        
        function obj = LvdGeometry(lvdData)
            obj.lvdData = lvdData;
            
            obj.points = GeometricPointSet(lvdData);
            obj.vectors = GeometricVectorSet(lvdData);
            obj.coordSyses = GeometricCoordSysSet(lvdData);
            obj.refFrames = GeometricRefFrameSet(lvdData);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            tf = tf || obj.points.usesGroundObj(groundObj);
            tf = tf || obj.vectors.usesGroundObj(groundObj);
            tf = tf || obj.coordSyses.usesGroundObj(groundObj);
            tf = tf || obj.refFrames.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            tf = tf || obj.points.usesGeometricPoint(point);
            tf = tf || obj.vectors.usesGeometricPoint(point);
            tf = tf || obj.coordSyses.usesGeometricPoint(point);
            tf = tf || obj.refFrames.usesGeometricPoint(point);
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            tf = tf || obj.points.usesGeometricVector(vector);
            tf = tf || obj.vectors.usesGeometricVector(vector);
            tf = tf || obj.coordSyses.usesGeometricVector(vector);
            tf = tf || obj.refFrames.usesGeometricVector(vector);
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            tf = tf || obj.points.usesGeometricCoordSys(coordSys);
            tf = tf || obj.vectors.usesGeometricCoordSys(coordSys);
            tf = tf || obj.coordSyses.usesGeometricCoordSys(coordSys);
            tf = tf || obj.refFrames.usesGeometricCoordSys(coordSys);
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            tf = tf || obj.points.usesGeometricRefFrame(refFrame);
            tf = tf || obj.vectors.usesGeometricRefFrame(refFrame);
            tf = tf || obj.coordSyses.usesGeometricRefFrame(refFrame);
            tf = tf || obj.refFrames.usesGeometricRefFrame(refFrame);
        end
    end
end