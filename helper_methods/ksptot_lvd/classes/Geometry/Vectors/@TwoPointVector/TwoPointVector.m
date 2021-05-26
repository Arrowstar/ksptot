classdef TwoPointVector < AbstractGeometricVector
    %TwoPointVector Provides the vector from point 1 to point 2.
    %   Detailed explanation goes here
    
    properties
        point1(1,1) AbstractGeometricPoint
        point2(1,1) AbstractGeometricPoint
        
        name(1,:) char
        lvdData LvdData
        
        %vector line
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end
    
    methods        
        function obj = TwoPointVector(point1, point2, name, lvdData) 
            obj.point1 = point1;
            obj.point2 = point2;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function vect = getVectorAtTime(obj, time, vehElemSet, inFrame)
            point1CartElem = obj.point1.getPositionAtTime(time, vehElemSet, inFrame);
            rVect1 = [point1CartElem.rVect];
            
            point2CartElem = obj.point2.getPositionAtTime(time, vehElemSet, inFrame);
            rVect2 = [point2CartElem.rVect];
            
            vect = rVect2 - rVect1;
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s ("%s" to "%s")', obj.getName(), obj.point1.getName(), obj.point2.getName());
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditTwoPointVectorGUI(obj, obj.lvdData);
        end
        
        function tf = isVehDependent(obj)
            tf = obj.point1.isVehDependent() || ...
                 obj.point2.isVehDependent();
        end
        
        function origin = getOriginPointInViewFrame(obj, time, vehElemSet, viewFrame)
            elemSet = obj.point1.getPositionAtTime(time, vehElemSet, viewFrame);
            origin = elemSet.rVect;
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.point1.usesGroundObj(groundObj) || ...
                 obj.point2.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = point == obj.point1 || ...
                 point == obj.point2;
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
            tf = lvdData.usesGeometricVector(obj);
        end
    end
end