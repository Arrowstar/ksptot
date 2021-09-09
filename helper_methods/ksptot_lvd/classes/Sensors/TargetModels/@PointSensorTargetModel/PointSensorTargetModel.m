classdef PointSensorTargetModel < AbstractSensorTarget
    %PointSensorTargetModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,:) char
        
        point AbstractGeometricPoint
        
        %display
        markerShape(1,1) MarkerStyleEnum = MarkerStyleEnum.Circle;
        markerFoundFaceColor(1,1) ColorSpecEnum = ColorSpecEnum.Green;
        markerFoundEdgeColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        markerNotFoundFaceColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        markerNotFoundEdgeColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        markerSize(1,1) double = 3;
        
        lvdData LvdData
    end
    
    methods
        function obj = PointSensorTargetModel(name, point, lvdData)
            arguments
                name(1,:) char
                point(1,1) AbstractGeometricPoint
                lvdData(1,1) LvdData
            end
            
            obj.name = name;
            obj.point = point;
            obj.lvdData = lvdData;
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
        
        function listboxStr = getListboxStr(obj)
            listboxStr = obj.name;
        end
        
        function shape = getMarkerShape(obj)
            shape = obj.markerShape;
        end
        
        function color = getFoundMarkerFaceColor(obj)
            color = obj.markerFoundFaceColor;
        end
        
        function color = getFoundMarkerEdgeColor(obj)
            color = obj.markerFoundEdgeColor;
        end
        
        function color = getNotFoundMarkerFaceColor(obj)
            color = obj.markerNotFoundFaceColor;
        end
        
        function color = getNotFoundMarkerEdgeColor(obj)
            color = obj.markerNotFoundEdgeColor;
        end
        
        function markerSize = getMarkerSize(obj)
            markerSize = obj.markerSize;
        end
        
        function useTf = openEditDialog(obj)
            useTf = false;
        end
        
        function tf = isInUse(obj, lvdData)
            tf = false;
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = obj.point == point;
        end
    end
end