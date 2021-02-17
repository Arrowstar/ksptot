classdef AbstractGeometricCoordSystem < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractGeometricCoordSystem Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods        
        [rotMatToInertial] = getCoordSysAtTime(obj, time, vehElemSet, inFrame)
        
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
        
        function tf = usesGeometricAngle(~, ~)
            tf = false;
        end
        
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