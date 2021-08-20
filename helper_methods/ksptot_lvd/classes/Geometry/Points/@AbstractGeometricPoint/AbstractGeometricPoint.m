classdef AbstractGeometricPoint < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractGeometricPoint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods        
        newCartElem = getPositionAtTime(obj, time, vehElemSet, inFrame)
        
        name = getName(obj)
        
        setName(obj, name)
        
        listboxStr = getListboxStr(obj)
        
        useTf = openEditDialog(obj, hKsptotMainGUI)
        
        tf = isVehDependent(obj)
        
        tf = canBePlotted(obj)
        
        bodyInfo = getOriginBody(obj)
        
        tf = usesGroundObj(obj, groundObj)
        
        tf = usesGeometricPoint(obj, point)
        
        tf = usesGeometricVector(obj, vector)
        
        tf = usesGeometricCoordSys(obj, coordSys)
        
        tf = usesGeometricRefFrame(obj, refFrame)
        
        tf = usesGeometricAngle(~, ~)
        
        tf = usesGeometricPlane(~, ~)
        
        tf = isInUse(obj, lvdData)
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