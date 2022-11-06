classdef CelestialBodyPoint < AbstractGeometricPoint
    %GroundObjectPoint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
         bodyInfo(1,1) KSPTOT_BodyInfo
         
         name(1,:) char
    end
    
    methods
        function obj = CelestialBodyPoint(bodyInfo, name)
            obj.bodyInfo = bodyInfo;
            obj.name = name;
        end
        
        function cartElem = getPositionAtTime(obj, time, ~, inFrame)
            cartElem = convertToFrame(convertToCartesianElementSet(obj.bodyInfo.getElementSetsForTimes(time)), inFrame);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Celestial Body: %s)', obj.getName(), obj.bodyInfo.name);
        end
        
        function useTf = openEditDialog(obj, ~)
%             useTf = lvd_EditCelestialBodyPointGUI(obj);
            
            output = AppDesignerGUIOutput({false});
            lvd_EditCelestialBodyPointGUI_App(obj, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(obj)
            tf = false;
        end
        
        function tf = canBePlotted(obj)
            tf = false;
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.bodyInfo;
        end
        
        function tf = usesGroundObj(~, ~)
            tf = false;
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
        
        function tf = usesGeometricPlane(~, ~)
            tf = false;
        end 
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricPoint(obj);
        end
    end
end