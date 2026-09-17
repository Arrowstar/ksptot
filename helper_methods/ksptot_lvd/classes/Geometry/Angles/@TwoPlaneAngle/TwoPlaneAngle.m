classdef TwoPlaneAngle < AbstractGeometricAngle
    %TwoPlaneAngle Output is the dihedral angle between two planes, i.e. the
    %angle between their unit normal vectors, in [0, pi].
    
    properties
        plane1(1,1) AbstractGeometricPlane
        plane2(1,1) AbstractGeometricPlane
        
        name(1,:) char
        lvdData LvdData
        
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Red;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.SolidLine;
    end
    
    methods        
        function obj = TwoPlaneAngle(plane1, plane2, name, lvdData) 
            obj.plane1 = plane1;
            obj.plane2 = plane2;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function angle = getAngleAtTime(obj, time, vehElemSet, inFrame)
            n1 = vect_normVector(obj.plane1.getPlaneNormVectAtTime(time, vehElemSet, inFrame));
            n2 = vect_normVector(obj.plane2.getPlaneNormVectAtTime(time, vehElemSet, inFrame));
            
            cosAngle = dot(n1, n2);
            cosAngle = max(-1, min(1, cosAngle));
            
            angle = acos(cosAngle);
        end
        
        function startPt = getAngleStartPointAtTime(obj, time, vehElemSet, inFrame)
            n1 = vect_normVector(obj.plane1.getPlaneNormVectAtTime(time, vehElemSet, inFrame));
            originCartElem = obj.plane1.getPlaneOriginPtAtTime(time, vehElemSet, inFrame);
            
            startPt = [originCartElem.rVect] + n1;
        end
        
        function anglePlaneNorm = getAnglePlaneNormalAtTime(obj, time, vehElemSet, inFrame)
            n1 = vect_normVector(obj.plane1.getPlaneNormVectAtTime(time, vehElemSet, inFrame));
            n2 = vect_normVector(obj.plane2.getPlaneNormVectAtTime(time, vehElemSet, inFrame));
            
            anglePlaneNorm = cross(n1, n2);
            
            bool = vecNormARH(anglePlaneNorm) == 0;
            if(any(bool))
                anglePlaneNorm(:,bool) = repmat([0;0;1], 1, sum(bool));
            end
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Angle Between Planes "%s" and "%s")', obj.getName(), obj.plane1.getName(), obj.plane2.getName());
        end
        
        function useTf = openEditDialog(obj)
            output = AppDesignerGUIOutput({false});
            lvd_EditTwoPlaneAngleGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(obj)
            tf = obj.plane1.isVehDependent() || ...
                 obj.plane2.isVehDependent();
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.plane1.usesGroundObj(groundObj) || ...
                 obj.plane2.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(~, ~)
            tf = false;
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
        
        function tf = usesGeometricPlane(obj, plane)
            tf = obj.plane1 == plane || ...
                 obj.plane2 == plane;
        end 
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricAngle(obj);
        end
    end
end
