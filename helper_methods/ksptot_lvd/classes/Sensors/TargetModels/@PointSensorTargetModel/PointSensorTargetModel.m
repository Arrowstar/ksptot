classdef PointSensorTargetModel < AbstractSensorTarget
    %PointSensorTargetModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,:) char
        
        point AbstractGeometricPoint
        
        %display
        markerShape(1,1) MarkerStyleEnum = MarkerStyleEnum.Circle;
        markerFoundFaceColor(1,3) double {mustBeBetween(markerFoundFaceColor, 0, 1)} = [76/255, 220/255, 0];
        markerFoundEdgeColor(1,3) double {mustBeBetween(markerFoundEdgeColor, 0, 1)} = [0, 0, 0];
        markerNotFoundFaceColor(1,3) double {mustBeBetween(markerNotFoundFaceColor, 0, 1)} = [0, 0, 0];
        markerNotFoundEdgeColor(1,3) double {mustBeBetween(markerNotFoundEdgeColor, 0, 1)} = [0, 0, 0];
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
        
        function numPts = getNumberOfTargetPts(obj)
            numPts = 1;
        end
        
        function strs = getTargetPtLabelStrs(obj)
            strs = string(obj.point.getName());
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (%s)', obj.name, obj.point.getName());
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
            output = AppDesignerGUIOutput({false});
            lvd_EditPointSensorTargetGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = isInUse(obj, lvdData)
            tf = false;
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = obj.point == point;
        end
    end

    methods(Static)
        function obj = loadobj(s)
            %loadobj Migrates missions saved with ColorSpecEnum colors.
            obj = lvd_constructMigrated('PointSensorTargetModel', {'name', 'point', 'lvdData'}, s, {'markerFoundFaceColor', 'markerFoundEdgeColor', 'markerNotFoundFaceColor', 'markerNotFoundEdgeColor'});
        end
    end
end
