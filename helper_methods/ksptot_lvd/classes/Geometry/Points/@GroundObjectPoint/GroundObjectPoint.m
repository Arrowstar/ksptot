classdef GroundObjectPoint < AbstractGeometricPoint
    %GroundObjectPoint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
         groundObj LaunchVehicleGroundObject
         
         name(1,:) char
    end
    
    methods
        function obj = GroundObjectPoint(groundObj, name)
            obj.groundObj = groundObj;
            obj.name = name;
        end
        
        function cartElem = getPositionAtTime(obj, time, ~, inFrame)
%             cartElem = repmat(CartesianElementSet.getDefaultElements(), [1 length(time)]);
            geoElem = repmat(GeographicElementSet.getDefaultElements(), [1 length(time)]);
            for(i=1:length(time))
                geoElem(i) = obj.groundObj.getStateAtTime(time(i));
            end
            
            cartElem = convertToFrame(convertToCartesianElementSet(geoElem), inFrame);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Ground Object: %s)', obj.getName(), obj.groundObj.name);
        end
        
        function useTf = openEditDialog(obj, ~)
%             useTf = lvd_EditGroundObjPointGUI(obj);

            output = AppDesignerGUIOutput({false});
            lvd_EditGroundObjPointGUI_App(obj, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(obj)
            tf = false;
        end
        
        function tf = canBePlotted(obj)
            tf = false;
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.groundObj.centralBodyInfo;
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.groundObj == groundObj;
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