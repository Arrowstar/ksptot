classdef ParallelToFrameAtTimeCoordSystem < AbstractGeometricCoordSystem
    %ParallelToFrameCoordSystem Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        frame AbstractReferenceFrame
        time(1,1) double = 0;
        
        name(1,:) char
        lvdData LvdData
    end
    
    methods        
        function obj = ParallelToFrameAtTimeCoordSystem(frame, time, name, lvdData)
            obj.frame = frame;
            obj.time = time;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function [rotMatToInertial] = getCoordSysAtTime(obj, ~, vehElemSet, ~)
            [~, ~, ~, rotMatToInertial] = obj.frame.getOffsetsWrtInertialOrigin(obj.time, vehElemSet);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Parallel To "%s" at UT = %0.3f sec)', obj.getName(), obj.frame.getNameStr(), obj.time);
        end
        
        function useTf = openEditDialog(obj)            
            output = AppDesignerGUIOutput({false});
            lvd_EditParallelToFrameAtTimeCoordSysGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(obj)
            if(obj.frame.typeEnum == ReferenceFrameEnum.UserDefined)
                tf = obj.frame.geometricFrame.isVehDependent();
            else
                tf = false;
            end
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.frame.usesGroundObj(groundObj);
        end
        
        function tf = usesGeometricPoint(obj, point)
            if(obj.frame.typeEnum == ReferenceFrameEnum.UserDefined)
                tf = obj.frame.geometricFrame.usesGeometricPoint(point);
            else
                tf = false;
            end
        end
        
        function tf = usesGeometricVector(obj, vector)
            if(obj.frame.typeEnum == ReferenceFrameEnum.UserDefined)
                tf = obj.frame.geometricFrame.usesGeometricVector(vector);
            else
                tf = false;
            end
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            if(obj.frame.typeEnum == ReferenceFrameEnum.UserDefined)
                tf = obj.frame.geometricFrame.usesGeometricCoordSys(coordSys);
            else
                tf = false;
            end
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            if(obj.frame.typeEnum == ReferenceFrameEnum.UserDefined)
                tf = obj.frame.geometricFrame.usesGeometricRefFrame(refFrame);
            else
                tf = false;
            end
        end
        
        function tf = usesGeometricAngle(obj, angle)
            if(obj.frame.typeEnum == ReferenceFrameEnum.UserDefined)
                tf = obj.frame.geometricFrame.usesGeometricAngle(angle);
            else
                tf = false;
            end
        end 
        
        function tf = usesGeometricPlane(obj, plane)
            if(obj.frame.typeEnum == ReferenceFrameEnum.UserDefined)
                tf = obj.frame.geometricFrame.usesGeometricPlane(plane);
            else
                tf = false;
            end
        end 
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricCoordSys(obj);
        end
    end
end