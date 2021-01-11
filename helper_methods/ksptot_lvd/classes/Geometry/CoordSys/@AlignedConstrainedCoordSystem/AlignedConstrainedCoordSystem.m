classdef AlignedConstrainedCoordSystem < AbstractGeometricCoordSystem
    %AlignedConstrainedCoordSystem Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        aVector(1,1) AbstractGeometricVector
        aVectorAxis(1,1) AlignedConstrainedCoordSysAxesEnum = AlignedConstrainedCoordSysAxesEnum.PosX;
        
        cVector(1,1) AbstractGeometricVector
        cVectorAxis(1,1) AlignedConstrainedCoordSysAxesEnum = AlignedConstrainedCoordSysAxesEnum.PosZ
        
        name(1,:) char
        lvdData LvdData
    end
    
    methods        
        function obj = AlignedConstrainedCoordSystem(aVector, aVectorAxis, cVector, cVectorAxis, name, lvdData)
            obj.aVector = aVector;
            obj.aVectorAxis = aVectorAxis;
            
            obj.cVector = cVector;
            obj.cVectorAxis = cVectorAxis;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function [rotMatToInertial] = getCoordSysAtTime(obj, time, vehElemSet, inFrame)
            aVect = normVector(obj.aVector.getVectorAtTime(time, vehElemSet, inFrame));
            aVectAxis = obj.aVectorAxis.vect;
            
            cVect = normVector(obj.cVector.getVectorAtTime(time, vehElemSet, inFrame));
            cVectAxis = obj.cVectorAxis.vect;
            
            cVectAA = vrrotvec(cVect,cVectAxis);
            cVectR = axang2rotm(cVectAA);

            aVectAR = cVectR * aVect;
            aVectAA = vrrotvec(aVectAR,aVectAxis);
            aVectR = axang2rotm(aVectAA);

            rotMatToInertial = aVectR * cVectR;
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Aligned "%s", Constrained "%s")', obj.getName(), obj.aVector.getName(), obj.cVector.getName());
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditAlignedConstrainedCoordSysGUI(obj, obj.lvdData);
        end
        
        function tf = usesGeometricPoint(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = vector == obj.aVector || ...
                 vector == obj.cVector;
        end
        
        function tf = usesGeometricCoordSys(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricRefFrame(~, ~)
            tf = false;
        end
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.geometry.usesGeometricCoordSys(obj);
        end
    end
end