classdef PlaneToPointVector < AbstractGeometricVector
    %PlaneToPointVector Provides the vector from a plane to a point.
    %   Source: https://mathworld.wolfram.com/Point-PlaneDistance.html
    
    properties
        point(1,1) AbstractGeometricPoint
        plane(1,1) AbstractGeometricPlane
        
        name(1,:) char
        lvdData LvdData
        
        %vector line
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end
    
    methods        
        function obj = PlaneToPointVector(point, plane, name, lvdData) 
            obj.point = point;
            obj.plane = plane;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function vect = getVectorAtTime(obj, time, vehElemSet, inFrame)
            [vect, ~] = obj.getVectAndOrigin(time, vehElemSet, inFrame);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s ("%s" to "%s")', obj.getName(), obj.plane.getName(), obj.point.getName());
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditPlaneToPointVectorGUI(obj, obj.lvdData);
        end
        
        function tf = isVehDependent(obj)
            tf = obj.point.isVehDependent() || ...
                 obj.plane.isVehDependent();
        end
        
        function origin = getOriginPointInViewFrame(obj, time, vehElemSet, viewFrame)
            [~, origin] = obj.getVectAndOrigin(time, vehElemSet, viewFrame);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.point.usesGroundObj(groundObj) || ...
                 obj.plane.usesGroundObj(groundObj);
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
        
        function tf = usesGeometricPlane(obj, plane)
            tf = plane == obj.plane;
        end 
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.geometry.usesGeometricVector(obj);
        end
    end
    
    methods(Access=private)
        function [vect, vectOrigin] = getVectAndOrigin(obj, time, vehElemSet, inFrame)
            pointCartElem = obj.point.getPositionAtTime(time, vehElemSet, inFrame);
            rVect = [pointCartElem.rVect];
            
            normvect = vect_normVector(obj.plane.getPlaneNormVectAtTime(time, vehElemSet, inFrame));
            originPtCartElem = obj.plane.getPlaneOriginPtAtTime(time, vehElemSet, inFrame);
            originPt = [originPtCartElem.rVect];
            
            vect = bsxfun(@times, dot(normvect, rVect - originPt), normvect);
            vectOrigin = rVect - vect;
        end
    end
end