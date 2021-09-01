classdef TwoVectorAngle < AbstractGeometricAngle
    %TwoVectorAngle Output is the angle between two input vectors
    %   Detailed explanation goes here
    
    properties
        vector1(1,1) AbstractGeometricVector
        vector2(1,1) AbstractGeometricVector
        
        name(1,:) char
        lvdData LvdData
        
%         %
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Red;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.SolidLine;
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
            
            vect1Hat = vect_normVector(vect1);
            vect2Hat = vect_normVector(vect2);
            
            vn = repmat([0;0;1], 1, numel(time));
            vecCrossProd = cross(vect1, vect2);
            bool = all(vn - vect1Hat == 0,1) | all(vn - vect2Hat == 0);
            if(any(bool))
                vn(:,bool) = vect_normVector(vecCrossProd(:,bool));
            end
            
            angle = acos(dot(vect1Hat, vect2Hat));
            
            angle = angle.*sign(dot(vn,vecCrossProd));
        end
        
        function startPt = getAngleStartPointAtTime(obj, time, vehElemSet, inFrame)
            startPt = obj.vector1.getVectorAtTime(time, vehElemSet, inFrame);
        end
        
        function anglePlaneNorm = getAnglePlaneNormalAtTime(obj, time, vehElemSet, inFrame)
            vect1 = obj.vector1.getVectorAtTime(time, vehElemSet, inFrame);
            vect2 = obj.vector2.getVectorAtTime(time, vehElemSet, inFrame);
            
            anglePlaneNorm = cross(vect1, vect2);
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
%             useTf = lvd_EditTwoVectorAngleGUI(obj, obj.lvdData);

            output = AppDesignerGUIOutput({false});
            lvd_EditTwoVectorAngleGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(obj)
            tf = obj.vector1.isVehDependent() || ...
                 obj.vector2.isVehDependent();
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.vector1.usesGroundObj(groundObj) || ...
                 obj.vector2.usesGroundObj(groundObj);
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
        
        function tf = usesGeometricPlane(~, ~)
            tf = false;
        end 
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricAngle(obj);
        end
    end
end