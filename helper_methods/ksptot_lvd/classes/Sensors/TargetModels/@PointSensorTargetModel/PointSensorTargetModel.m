classdef PointSensorTargetModel < AbstractSensorTarget
    %PointSensorTargetModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        point AbstractGeometricPoint
    end
    
    methods
        function obj = PointSensorTargetModel(point)
            obj.point = point;
        end
        
        function rVect = getTargetPositions(obj, time, vehElemSet, inFrame)
            arguments
                obj(1,1) PointSensorTargetModel
                time(1,1) double
                vehElemSet(1,1) CartesianElementSet
                inFrame(1,1) AbstractReferenceFrame
            end
            
            newCartElem = obj.point.getPositionAtTime(time, vehElemSet, inFrame);
            rVect = newCartElem.rVect;
        end
    end
end