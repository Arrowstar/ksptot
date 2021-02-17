classdef PointVectorPlane < AbstractGeometricPlane
    %PointVectorPlane Output is the angle between two input vectors
    %   Detailed explanation goes here
    
    properties
        point(1,1) AbstractGeometricPoint
        vector(1,1) AbstractGeometricVector
        
        name(1,:) char
        lvdData LvdData
        
%         %
%         lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
%         lineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end
    
    methods        
        function obj = PointVectorPlane(point, vector, name, lvdData) 
            obj.point = point;
            obj.vector = vector;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function normvect = getPlaneNormVectAtTime(obj, time, vehElemSet, inFrame)
            normvect = obj.vector.getVectorAtTime(time, vehElemSet, inFrame);
        end
        
        function originPt = getPlaneOriginPtAtTime(obj, time, vehElemSet, inFrame)
            originPt = obj.point.getPositionAtTime(time, vehElemSet, inFrame);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Normal: "%s", Origin: "%s")', obj.getName(), obj.vector.getName(), obj.point.getName());
        end
        
        function useTf = openEditDialog(obj)
%             useTf = lvd_EditCrossProductVectorGUI(obj, obj.lvdData);
        end
        
        function tf = isVehDependent(obj)
            tf = obj.point.isVehDependent() || ...
                 obj.vector.isVehDependent();
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.point.usesGroundObj(groundObj) || ...
                 obj.vector.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = obj.point == point;
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = obj.vector == vector;
        end
        
        function tf = usesGeometricCoordSys(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricRefFrame(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricAngle(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricPlane(~, ~)
            tf = false;
        end     
        
        function tf = isInUse(obj, lvdData)
%             tf = lvdData.geometry.usesGeometricAngle(obj);
        end
    end
end