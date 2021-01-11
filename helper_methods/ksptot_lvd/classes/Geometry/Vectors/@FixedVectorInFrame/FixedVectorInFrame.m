classdef FixedVectorInFrame < AbstractGeometricVector
    %FixedVectorInFrame Provides the vector from point 1 to point 2.
    %   Detailed explanation goes here
    
    properties
        cartElem(1,1) CartesianElementSet 
        
        name(1,:) char
    end
    
    methods        
        function obj = FixedVectorInFrame(vect, frame, name) 
            obj.cartElem = CartesianElementSet(0, vect(:), [0;0;0], frame);
            
            obj.name = name;
        end
        
        function vect = getVectorAtTime(obj, time, inFrame)
            obj.cartElem.time = time;
            newCartElem = obj.cartElem.convertToFrame(inFrame);
            vect = newCartElem.rVect;
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
            tf = lvdData.geometry.usesGeometricVector(obj);
        end
    end
end