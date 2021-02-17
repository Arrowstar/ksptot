classdef ProjectedVector < AbstractGeometricVector
    %ProjectedVector Output is the cross product of two input vectors
    %   Detailed explanation goes here
    
    properties
        projVect(1,1) AbstractGeometricVector
        normVect(1,1) AbstractGeometricVector
        
        name(1,:) char
        lvdData LvdData
        
        %vector line
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end
    
    methods        
        function obj = ProjectedVector(projVect, normVect, name, lvdData) 
            obj.projVect = projVect;
            obj.normVect = normVect;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function vect = getVectorAtTime(obj, time, vehElemSet, inFrame)
            projVector = obj.projVect.getVectorAtTime(time, vehElemSet, inFrame);            
            normVector = obj.normVect.getVectorAtTime(time, vehElemSet, inFrame);
            
            normVectorNormSqr = vecNormARH(normVector).^2;
            normVectFactor = (dot(projVector,normVector)./normVectorNormSqr);
            
            vect = (projVector - bsxfun(@times, normVectFactor, normVector));
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s ("%s" projected onto plane of "%s")', obj.getName(), obj.projVect.getName(), obj.normVect.getName());
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditProjectedVectorGUI(obj, obj.lvdData);
        end
        
        function tf = isVehDependent(obj)
            tf = obj.projVect.isVehDependent() || ...
                 obj.normVect.isVehDependent();
        end
        
        function origin = getOriginPointInViewFrame(obj, time, vehElemSet, viewFrame)
            origin = [0;0;0];
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.projVect.usesGroundObj(groundObj) || ...
                 obj.normVect.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = obj.projVect == vector || ...
                 obj.normVect == vector;
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
            tf = lvdData.geometry.usesGeometricVector(obj);
        end
    end
end