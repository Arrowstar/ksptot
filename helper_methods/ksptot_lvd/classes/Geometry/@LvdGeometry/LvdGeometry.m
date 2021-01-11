classdef LvdGeometry < matlab.mixin.SetGet
    %LvdGeometry Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        points GeometricPointSet = GeometricPointSet.empty(1,0)
        vectors GeometricVectorSet = GeometricVectorSet.empty(1,0)
        %coord sys here
        %ref frames here
        
        lvdData LvdData
    end
    
    methods        
        function obj = LvdGeometry(lvdData)
            obj.lvdData = lvdData;
            
            obj.points = GeometricPointSet(lvdData);
            obj.vectors = GeometricVectorSet(lvdData);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            tf = tf || obj.points.usesGroundObj(groundObj);
            tf = tf || obj.vectors.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            tf = tf || obj.points.usesGeometricPoint(point);
            tf = tf || obj.vectors.usesGeometricPoint(point);
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            tf = tf || obj.points.usesGeometricVector(vector);
            tf = tf || obj.vectors.usesGeometricVector(vector);
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            tf = tf || obj.points.usesGeometricCoordSys(coordSys);
            tf = tf || obj.vectors.usesGeometricCoordSys(coordSys);
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            tf = tf || obj.points.usesGeometricRefFrame(refFrame);
            tf = tf || obj.vectors.usesGeometricRefFrame(refFrame);
        end
    end
end