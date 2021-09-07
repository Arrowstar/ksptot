classdef(Abstract) AbstractSensorTarget < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractSensorTarget Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        rVect = getTargetPositions(obj, time, vehElemSet, inFrame);
        
        shape = getMarkerShape(obj)
        color = getFoundMarkerFaceColor(obj)
        color = getFoundMarkerEdgeColor(obj)
        color = getNotFoundMarkerFaceColor(obj)
        color = getNotFoundMarkerEdgeColor(obj)
        markerSize = getMarkerSize(obj);
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = false;
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = false;
        end
    end
end