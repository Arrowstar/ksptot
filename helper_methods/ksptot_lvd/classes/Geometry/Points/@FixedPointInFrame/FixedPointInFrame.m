classdef FixedPointInFrame < AbstractGeometricPoint
    %FixedPointInFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cartElem(1,1) CartesianElementSet
        
        name(1,:) char
    end
    
    methods
        function obj = FixedPointInFrame(rVect, frame, name)
            obj.cartElem = CartesianElementSet(0, rVect(:), [0;0;0], frame);
            obj.name = name;
        end
        
        function newCartElem = getPositionAtTime(obj, time, ~, inFrame)
            obj.cartElem.time = time;
            newCartElem = obj.cartElem.convertToFrame(inFrame);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Fixed in Frame: %s)', obj.getName(), obj.cartElem.frame.getNameStr());
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditFixedInFramePointGUI(obj);
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.cartElem.frame.getOriginBody();
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
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.geometry.usesGeometricPoint(obj);
        end
        
        function rVect = getRVect(obj)
            rVect = obj.cartElem.rVect;
        end
        
        function setRVect(obj, rVect)
            obj.cartElem.rVect = rVect;
        end
        
        function frame = getFrame(obj)
            frame = obj.cartElem.frame;
        end
    end
end