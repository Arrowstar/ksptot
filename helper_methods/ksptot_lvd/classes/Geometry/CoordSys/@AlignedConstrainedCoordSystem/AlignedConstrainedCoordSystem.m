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
            aVect = obj.aVector.getVectorAtTime(time, vehElemSet, inFrame);
            
            bool = vecNormARH(aVect) == 0;
            if(any(bool))
                aVect(:,bool) = [1;0;0];
            end
            aVect = vect_normVector(aVect);
%             if(norm(aVect) == 0)
%                 aVect = [1;0;0];
%             else
%                 aVect = vect_normVector(aVect);
%             end
            
            aVectAxis = repmat(obj.aVectorAxis.vect, [1 length(time)]);
            
            cVect = obj.cVector.getVectorAtTime(time, vehElemSet, inFrame);
            
            bool = vecNormARH(cVect) == 0;
            if(any(bool))
                cVect(:,bool) = [0;0;1];
            end
            cVect = vect_normVector(cVect);
%             if(norm(cVect) == 0)
%                 cVect = [0;0;1];
%             else
%                 cVect = vect_normVector(cVect);
%             end
            
            cVectAxis = repmat(obj.cVectorAxis.vect, [1 length(time)]);
            
            cVectAA = NaN(length(time), 4);
            for(i=1:length(time))
                cVectAA(i,:) = vrrotvec(cVect(:,i),cVectAxis(:,i));
            end
            cVectR = axang2rotmARH(cVectAA);

            aVectAR = squeeze(pagemtimes(cVectR, permute(aVect, [1 3 2])));
            
            aVectAA = NaN(length(time), 4);
            for(i=1:length(time))
                aVectAA(i,:) = vrrotvec(aVectAR(:,i),aVectAxis(:,i));
            end
            aVectR = axang2rotmARH(aVectAA);

            rotMatToInertial = permute(pagemtimes(aVectR, cVectR), [2 1 3]);
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
%             useTf = lvd_EditAlignedConstrainedCoordSysGUI(obj, obj.lvdData);

            output = AppDesignerGUIOutput({false});
            lvd_EditAlignedConstrainedCoordSysGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(obj)
            tf = obj.aVector.isVehDependent() || ...
                 obj.cVector.isVehDependent();
        end

        function tf = usesGroundObj(obj, groundObj)
            tf = obj.aVector.usesGroundObj(groundObj) || ...
                 obj.cVector.usesGroundObj(groundObj);
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
        
        function tf = usesGeometricAngle(~, ~)
            tf = false;
        end 
        
        function tf = usesGeometricPlane(~, ~)
            tf = false;
        end 
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricCoordSys(obj);
        end
    end
end