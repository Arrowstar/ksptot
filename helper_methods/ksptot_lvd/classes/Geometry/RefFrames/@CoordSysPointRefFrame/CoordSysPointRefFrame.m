classdef CoordSysPointRefFrame < AbstractGeometricRefFrame
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
               
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getRefFrameAtTime(obj, time, vehElemSet, inFrame)
            ce = obj.origin.getPositionAtTime(time, vehElemSet, inFrame);
            posOffsetOrigin = [ce.rVect];
            velOffsetOrigin = [ce.vVect];
            
            rotMatToInertial = obj.coordSys.getCoordSysAtTime(time, vehElemSet, inFrame);
            
            if(obj.coordSys.isVehDependent() == false)
                h = 0.01;
                rotMatToInertial12 = rotMatToInertial;
                rotMatToInertial32 = obj.coordSys.getCoordSysAtTime(time + h, vehElemSet, inFrame);
                rotMatToInertial23 = permute(rotMatToInertial32, [2 1 3]);
                rotMatToInertial13 = mtimesx(rotMatToInertial23,rotMatToInertial12);
                
                axang = rotm2axangARH(rotMatToInertial13);
                axang = axang';
                rotAxes = vect_normVector(axang(1:3,:));
                angleVel = axang(4,:)/h;
                
                angVelWrtOrigin = bsxfun(@times, rotAxes, angleVel);
                
            else
                angVelWrtOrigin = repmat([0;0;0], [1, length(time)]);
            end
        end
        
        function name = getName(obj)
            name = obj.name;
        end
                
        function setName(obj, name)
            obj.name = name;
        end
                
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s ("%s" at origin "%s")', obj.getName(), obj.coordSys.getName(), obj.origin.getName());
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditCoordSysOriginRefFrameGUI(obj, obj.lvdData);
        end
        
        function tf = isVehDependent(obj)
            tf = obj.coordSys.isVehDependent() || ...
                 obj.origin.isVehDependent();
        end
        
        function tf = originIsVehDependent(obj)
            tf = obj.origin.isVehDependent();
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.coordSys.usesGroundObj(groundObj) || ...
                 obj.origin.usesGroundObj(groundObj);
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
        
        function tf = usesGeometricAngle(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricPlane(~, ~)
            tf = false;
        end 
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricRefFrame(obj);
        end
    end
end