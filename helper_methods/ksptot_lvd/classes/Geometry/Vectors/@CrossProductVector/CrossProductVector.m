classdef CrossProductVector < AbstractGeometricVector
    %CrossProductVector Output is the cross product of two input vectors
    %   Detailed explanation goes here
    
    properties
        vector1(1,1) AbstractGeometricVector
        vector2(1,1) AbstractGeometricVector
        
        name(1,:) char
        lvdData LvdData
        
        %vector line
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end
    
    methods        
        function obj = CrossProductVector(vector1, vector2, name, lvdData) 
            obj.vector1 = vector1;
            obj.vector2 = vector2;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function vect = getVectorAtTime(obj, time, vehElemSet, inFrame)
            vect1 = obj.vector1.getVectorAtTime(time, vehElemSet, inFrame);
            vect2 = obj.vector2.getVectorAtTime(time, vehElemSet, inFrame);
            
            vect = crossARH(vect1(:), vect2(:));
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s ("%s" cross "%s")', obj.getName(), obj.vector1.getName(), obj.vector2.getName());
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditCrossProductVectorGUI(obj, obj.lvdData);
        end
        
        function tf = isVehDependent(obj)
            tf = obj.vector1.isVehDependent() || ...
                 obj.vector2.isVehDependent();
        end
        
        function origin = getOriginPointInViewFrame(obj, time, vehElemSet, viewFrame)
            origin = [0;0;0];
        end
        
        function tf = usesGeometricPoint(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = obj.vector1 == vector || ...
                 obj.vector2 == vector;
        end
        
        function tf = usesGeometricCoordSys(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricRefFrame(~, ~)
            tf = false;
        end
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.geometry.usesGeometricVector(obj);
        end
    end
end