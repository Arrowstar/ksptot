classdef LvdGeometry < matlab.mixin.SetGet
    %LvdGeometry Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        points GeometricPointSet = GeometricPointSet.empty(1,0)
        %vectors here
        %coord sys here
        %ref frames here
        
        lvdData LvdData
    end
    
    methods        
        function obj = LvdGeometry(lvdData)
            obj.lvdData = lvdData;
            
            obj.points = GeometricPointSet(lvdData);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            tf = tf || obj.points.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            tf = tf || obj.points.usesGeometricPoint(point);
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            tf = tf || obj.points.usesGeometricVector(vector);
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            tf = tf || obj.points.usesGeometricCoordSys(coordSys);
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            tf = tf || obj.points.usesGeometricRefFrame(refFrame);
        end
    end
end