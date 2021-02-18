classdef ThreePointPlane < AbstractGeometricPlane
    %ThreePointPlane Output is the angle between two input vectors
    %   Detailed explanation goes here
    
    properties
        point1(1,1) AbstractGeometricPoint
        point2(1,1) AbstractGeometricPoint
        point3(1,1) AbstractGeometricPoint
        
        name(1,:) char
        lvdData LvdData
        
        %display
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Green;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.DashedLine;
        edgeLength(1,1) double = 100; %km
        alpha(1,1) double = 0.5;
    end
    
    methods        
        function obj = ThreePointPlane(point1, point2, point3, name, lvdData) 
            obj.point1 = point1;
            obj.point2 = point2;
            obj.point3 = point3;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function normvect = getPlaneNormVectAtTime(obj, time, vehElemSet, inFrame)
            point1Pos = obj.point1.getPositionAtTime(time, vehElemSet, inFrame);
            point2Pos = obj.point2.getPositionAtTime(time, vehElemSet, inFrame);
            point3Pos = obj.point3.getPositionAtTime(time, vehElemSet, inFrame);
            
            vect12 = [point2Pos.rVect] - [point1Pos.rVect];
            vect13 = [point3Pos.rVect] - [point1Pos.rVect];
            normvect = cross(vect12, vect13);
            
            vecNorms = vecNormARH(normvect);
            bool = vecNorms == 0;
            if(any(bool))
                normvect(:,bool) = [0;0;1];
            end
            
            normvect = vect_normVector(normvect);
        end
        
        function originPt = getPlaneOriginPtAtTime(obj, time, vehElemSet, inFrame)
            originPt = obj.point1.getPositionAtTime(time, vehElemSet, inFrame);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Origin Pt: "%s", Point 2: "%s", Point 3: "%s")', obj.getName(), obj.point1.getName(), obj.point2.getName(), obj.point3.getName());
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditThreePointPlaneGUI(obj, obj.lvdData);
        end
        
        function tf = isVehDependent(obj)
            tf = obj.point1.isVehDependent() || ...
                 obj.point2.isVehDependent() || ...
                 obj.point3.isVehDependent();
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.point1.usesGroundObj(groundObj) || ...
                 obj.point2.usesGroundObj(groundObj) || ...
                 obj.point3.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = obj.point1 == point || ...
                 obj.point2 == point || ...
                 obj.point3 == point;
        end
        
        function tf = usesGeometricVector(~, ~)
            tf = false;
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
            tf = lvdData.geometry.usesGeometricPlane(obj);
        end
    end
end