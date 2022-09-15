classdef PointVelocityVector < AbstractGeometricVector
    %PointVelocityVector Provides the vector from point 1 to point 2.
    %   Detailed explanation goes here
    
    properties
        point(1,1) AbstractGeometricPoint
        
        name(1,:) char
        lvdData LvdData
        
        %vector line
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end
    
    methods        
        function obj = PointVelocityVector(point, name, lvdData) 
            obj.point = point;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function vect = getVectorAtTime(obj, time, vehElemSet, inFrame)
            pointCartElem = obj.point.getPositionAtTime(time, vehElemSet, inFrame);
            vVect = [pointCartElem.vVect];
            
            vect = vVect;
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s ("%s" Velocity Vector)', obj.getName(), obj.point.getName());
        end
        
        function useTf = openEditDialog(obj)            
            output = AppDesignerGUIOutput({false});
            lvd_EditPointVelocityVectorGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(obj)
            tf = obj.point.isVehDependent();
        end
        
        function origin = getOriginPointInViewFrame(obj, time, vehElemSet, viewFrame)
            elemSet = obj.point.getPositionAtTime(time, vehElemSet, viewFrame);
            origin = elemSet.rVect;
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.point.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = point == obj.point;
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