classdef(Abstract) AbstractLaunchVehicleCalculusCalc < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractLaunchVehicleCalculusCalc Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        
        quantStr char 
        refBody KSPTOT_BodyInfo
        unitStr char
        
        id(1,1) double = 0;
    end
    
    methods        
        nameStr = getNameStr(obj);
        
        initState = createInitialState(obj);
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesCalculusCalc(obj);
        end
    end
    
    methods(Sealed)
        function tf = eq(a,b)
            tf = [a.id] == [b.id];
        end
    end
end