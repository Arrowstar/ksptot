classdef LvdGeometry < matlab.mixin.SetGet
    %LvdGeometry Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        points GeometricPointSet = GeometricPointSet.empty(1,0)
        vectors GeometricVectorSet = GeometricVectorSet.empty(1,0)
        coordSyses GeometricCoordSysSet = GeometricCoordSysSet.empty(1,0)
        refFrames GeometricRefFrameSet = GeometricRefFrameSet.empty(1,0)
        angles GeometricAngleSet = GeometricAngleSet.empty(1,0);
        planes GeometricPlaneSet = GeometricPlaneSet.empty(1,0);
        
        lvdData LvdData
    end
    
    methods        
        function obj = LvdGeometry(lvdData)
            obj.lvdData = lvdData;
            
            obj.points = GeometricPointSet(lvdData);
            obj.vectors = GeometricVectorSet(lvdData);
            obj.coordSyses = GeometricCoordSysSet(lvdData);
            obj.refFrames = GeometricRefFrameSet(lvdData);
            obj.angles = GeometricAngleSet(lvdData);
            obj.planes = GeometricPlaneSet(lvdData);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            tf = tf || obj.points.usesGroundObj(groundObj);
            tf = tf || obj.vectors.usesGroundObj(groundObj);
            tf = tf || obj.coordSyses.usesGroundObj(groundObj);
            tf = tf || obj.refFrames.usesGroundObj(groundObj);
            tf = tf || obj.angles.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            tf = tf || obj.points.usesGeometricPoint(point);
            tf = tf || obj.vectors.usesGeometricPoint(point);
            tf = tf || obj.coordSyses.usesGeometricPoint(point);
            tf = tf || obj.refFrames.usesGeometricPoint(point);
            tf = tf || obj.angles.usesGeometricPoint(point);
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            tf = tf || obj.points.usesGeometricVector(vector);
            tf = tf || obj.vectors.usesGeometricVector(vector);
            tf = tf || obj.coordSyses.usesGeometricVector(vector);
            tf = tf || obj.refFrames.usesGeometricVector(vector);
            tf = tf || obj.angles.usesGeometricVector(vector);
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            tf = tf || obj.points.usesGeometricCoordSys(coordSys);
            tf = tf || obj.vectors.usesGeometricCoordSys(coordSys);
            tf = tf || obj.coordSyses.usesGeometricCoordSys(coordSys);
            tf = tf || obj.refFrames.usesGeometricCoordSys(coordSys);
            tf = tf || obj.angles.usesGeometricCoordSys(coordSys);
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            tf = tf || obj.points.usesGeometricRefFrame(refFrame);
            tf = tf || obj.vectors.usesGeometricRefFrame(refFrame);
            tf = tf || obj.coordSyses.usesGeometricRefFrame(refFrame);
            tf = tf || obj.refFrames.usesGeometricRefFrame(refFrame);
            tf = tf || obj.angles.usesGeometricRefFrame(refFrame);
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = false;
            tf = tf || obj.points.usesGeometricAngle(angle);
            tf = tf || obj.vectors.usesGeometricAngle(angle);
            tf = tf || obj.coordSyses.usesGeometricAngle(angle);
            tf = tf || obj.refFrames.usesGeometricAngle(angle);
            tf = tf || obj.angles.usesGeometricAngle(angle);
        end
    end
    
    methods(Static)
        function obj = loadobj(obj)
            if(isempty(obj.points))
                obj.points = GeometricPointSet(obj.lvdData);
            end
            
            if(isempty(obj.vectors))
                obj.vectors = GeometricVectorSet(obj.lvdData);
            end
            
            if(isempty(obj.coordSyses))
                obj.coordSyses = GeometricCoordSysSet(obj.lvdData);
            end
            
            if(isempty(obj.refFrames))
                obj.refFrames = GeometricRefFrameSet(obj.lvdData);
            end
            
            if(isempty(obj.angles))
                obj.angles = GeometricAngleSet(obj.lvdData);
            end   
            
            if(isempty(obj.planes))
                obj.planes = GeometricPlaneSet(obj.lvdData);
            end
        end
    end
end