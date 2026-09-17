classdef AbstractGeometricAngle < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractGeometricAngle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods        
        angle = getAngleAtTime(obj, time, vehElemSet, inFrame)
        
        startPt = getAngleStartPointAtTime(obj, time, vehElemSet, inFrame)
        
        name = getName(obj)
        
        setName(obj, name)
        
        listboxStr = getListboxStr(obj)
        
        useTf = openEditDialog(obj)
        
        tf = isVehDependent(obj)
        
        tf = usesGroundObj(obj, groundObj)
        
        tf = usesGeometricPoint(obj, point)
        
        tf = usesGeometricVector(obj, vector)
        
        tf = usesGeometricCoordSys(obj, coordSys)
        
        tf = usesGeometricRefFrame(obj, refFrame)
        
        tf = usesGeometricAngle(obj, angle)
        
        tf = usesGeometricPlane(~, ~)
        
        tf = isInUse(obj, lvdData)
    end

    methods
        function tf = isDimensionless(~)
            %isDimensionless False for a true angle (getAngleAtTime returns
            %radians and the display draws an arc).  A scalar that only
            %borrows this interface (VectorDotProductAngle) overrides this to
            %true so consumers report its raw value instead of converting it
            %to degrees, and so the 3D view does not try to draw it.
            tf = false;
        end
    end

    methods(Sealed)
        function tf = eq(a,b)
            tf = eq@handle(a,b);
        end
        
        function tf = ne(a,b)
            tf = ne@handle(a,b);
        end
    end
end