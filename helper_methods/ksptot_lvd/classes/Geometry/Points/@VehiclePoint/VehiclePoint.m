classdef VehiclePoint < AbstractGeometricPoint
    %VehiclePoint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties         
         name(1,:) char
    end

    properties(Constant)
        emptyBodyInfo KSPTOT_BodyInfo = KSPTOT_BodyInfo.empty(1,0);
    end
    
    methods
        function obj = VehiclePoint(name)
            obj.name = name;
        end
        
        function cartElem = getPositionAtTime(~, ~, vehElemSet, inFrame)
            cartElem = convertToFrame(convertToCartesianElementSet(vehElemSet), inFrame);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Vehicle)', obj.getName());
        end
        
        function useTf = openEditDialog(obj, ~)
            useTf = lvd_EditVehiclePointGUI(obj);
        end
        
        function tf = isVehDependent(obj)
            tf = true;
        end
        
        function tf = canBePlotted(obj)
            tf = false;
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.emptyBodyInfo;
%             warning("Request for vehicle point origin body.")
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
            tf = lvdData.geometry.usesGeometricPoint(obj);
        end
    end
end