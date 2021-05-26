classdef VectorPlaneAngle < AbstractGeometricAngle
    %VectorPlaneAngle Output is the angle between a plane and a vector
    %   Detailed explanation goes here
    
    properties
        vector(1,1) AbstractGeometricVector
        plane(1,1) AbstractGeometricPlane
        
        name(1,:) char
        lvdData LvdData
        
%         %
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Red;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.SolidLine;
    end
    
    methods        
        function obj = VectorPlaneAngle(vector, plane, name, lvdData) 
            obj.vector = vector;
            obj.plane = plane;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function angle = getAngleAtTime(obj, time, vehElemSet, inFrame)
            vect = obj.vector.getVectorAtTime(time, vehElemSet, inFrame);
            normVect = obj.plane.getPlaneNormVectAtTime(time, vehElemSet, inFrame);
            
            vectHat = vect_normVector(vect);
            normVect = vect_normVector(normVect);
            
            angle = asin(abs(dot(vectHat, normVect)));
        end
        
        function startPt = getAngleStartPointAtTime(obj, time, vehElemSet, inFrame)
            vect = obj.vector.getVectorAtTime(time, vehElemSet, inFrame);
            
            d = vect_normVector(vect);
            o = obj.vector.getOriginPointInViewFrame(time, vehElemSet, inFrame);
            N = vect_normVector(obj.plane.getPlaneNormVectAtTime(time, vehElemSet, inFrame));
            aCartElem = obj.plane.getPlaneOriginPtAtTime(time, vehElemSet, inFrame);
            a = [aCartElem.rVect];
            
            N1 = N(1,:);
            N2 = N(2,:);
            N3 = N(3,:);
            
            o1 = o(1,:);
            o2 = o(2,:);
            o3 = o(3,:);
            
            a1 = a(1,:);
            a2 = a(2,:);
            a3 = a(3,:);
            
            d1 = d(1,:);
            d2 = d(2,:);
            d3 = d(3,:);
            
            tNum = N1.*(o1-a1) + N2.*(o2-a2) + N3.*(o3-a3);
            tDen = N1.*d1 + N2.*d2 + N3.*d3;
            t = -tNum./tDen;
            
            x = o1 + d1.*t;
            y = o2 + d2.*t;
            z = o3 + d3.*t;
            
            startPt = [x;y;z] + vect;
        end
        
        function anglePlaneNorm = getAnglePlaneNormalAtTime(obj, time, vehElemSet, inFrame)
            vect = obj.vector.getVectorAtTime(time, vehElemSet, inFrame);
            vectHat = vect_normVector(vect);
            normVect = obj.plane.getPlaneNormVectAtTime(time, vehElemSet, inFrame);
            
            normVectorNormSqr = vecNormARH(normVect).^2;
            normVectFactor = (dot(vect,normVect)./normVectorNormSqr);
            
            projVect = (vect - bsxfun(@times, normVectFactor, normVect));
            projVectHat = vect_normVector(projVect);
            
            for(i=1:size(vectHat,2))
                if(vectHat(3,i) >= projVectHat(3,i))
                    anglePlaneNorm(:,i) = cross(vectHat(:,i), projVectHat(:,i)); %#ok<AGROW>
                else
                    anglePlaneNorm(:,i) = -cross(vectHat(:,i), projVectHat(:,i)); %#ok<AGROW>
                end
            end
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Angle Between "%s" and "%s")', obj.getName(), obj.vector.getName(), obj.plane.getName());
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditVectorPlaneAngleGUI(obj, obj.lvdData);
        end
        
        function tf = isVehDependent(obj)
            tf = obj.vector.isVehDependent() || ...
                 obj.plane.isVehDependent();
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.vector.usesGroundObj(groundObj) || ...
                 obj.plane.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(~, ~)
            tf = false;
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
        
        function tf = usesGeometricPlane(obj, plane)
            tf = obj.plane == plane;
        end 
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricAngle(obj);
        end
    end
end