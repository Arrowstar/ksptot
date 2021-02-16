classdef TwoVectorAngle < AbstractGeometricVector
    %TwoVectorAngle Output is the cross product of two input vectors
    %   Detailed explanation goes here
    
    properties
        vector1(1,1) AbstractGeometricVector
        vector2(1,1) AbstractGeometricVector
        
        name(1,:) char
        lvdData LvdData
        
%         %
%         lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
%         lineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end
    
    methods        
        function obj = TwoVectorAngle(vector1, vector2, name, lvdData) 
            obj.vector1 = vector1;
            obj.vector2 = vector2;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function angle = getAngleAtTime(obj, time, vehElemSet, inFrame)
            vect1 = obj.vector1.getVectorAtTime(time, vehElemSet, inFrame);
            vect2 = obj.vector2.getVectorAtTime(time, vehElemSet, inFrame);
            vn = repmat([0;0;1], 1, numel(time));
            
            vect1Hat = vect_normVector(vect1);
            vect2Hat = vect_normVector(vect2);
            
            angle = acos(dot(vect1Hat, vect2Hat));
            vecCrossProd = cross(vect1, vect2);
            angle = angle.*sign(dot(vn,vecCrossProd));
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Angle Between "%s" and "%s")', obj.getName(), obj.vector1.getName(), obj.vector2.getName());
        end
        
        function useTf = openEditDialog(obj)
%             useTf = lvd_EditCrossProductVectorGUI(obj, obj.lvdData);
        end
        
        function tf = isVehDependent(obj)
            tf = obj.vector1.isVehDependent() || ...
                 obj.vector2.isVehDependent();
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
        
        function tf = usesGeometricAngle(~, ~)
            tf = false;
        end
        
        function tf = isInUse(obj, lvdData)
%             tf = lvdData.geometry.usesGeometricVector(obj);
        end
    end
end