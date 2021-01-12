classdef CoordSysPointRefFrame < AbstractGeometricRefFrame & AbstractReferenceFrame
    %CoordSysPointRefFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        coordSys(1,1) AbstractGeometricCoordSystem
        origin(1,1) AbstractGeometricPoint
        
        name(1,:) char
        lvdData LvdData
    end
    
    properties(Constant)
        typeEnum = ReferenceFrameEnum.UserDefined;
    end
    
    methods        
        function obj = CoordSysPointRefFrame(coordSys, origin, name, lvdData)
            obj.coordSys = coordSys;
            obj.origin = origin;
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time)
            baseFrame = obj.lvdData.getBaseFrame();
            
            [posOffsetOrigin, velOffsetOrigin, rotMatToInertial] = obj.getRefFrameAtTime(time, vehElemSet, baseFrame);
            
            angVelWrtOrigin = [0;0;0];
        end
        
        function [posOffsetOrigin, velOffsetOrigin, rotMatToInertial] = getRefFrameAtTime(obj, time, vehElemSet, inFrame)
            ce = obj.origin.getPositionAtTime(time, vehElemSet, inFrame);
            posOffsetOrigin = ce.rVect;
            velOffsetOrigin = ce.vVect;
            
            rotMatToInertial = obj.coordSys.getCoordSysAtTime(time, vehElemSet, inFrame);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function nameStr = getNameStr(obj)
            nameStr = obj.getName();
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.origin.getOriginBody();
        end
        
        function setOriginBody(~, ~)
            %do nothing, I think
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s ("%s" at origin "%s")', obj.getName(), obj.coordSys.getName(), obj.origin.getName());
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditCoordSysOriginRefFrameGUI(obj, obj.lvdData);
        end
        
        function editFrameDialogUI(obj)
            obj.openEditDialog();
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = obj.origin == point;
        end
        
        function tf = usesGeometricVector(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = obj.coordSys == coordSys;
        end
        
        function tf = usesGeometricRefFrame(~, ~)
            tf = false;
        end
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.geometry.usesGeometricRefFrame(obj);
        end
    end
end