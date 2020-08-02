classdef(Abstract) AbstractLaunchVehicleElectricalPowerSrcSnk < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractLaunchVehicleElectricalPowerSrc Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Abstract)
        id
    end
    
    methods
        name = getName(obj);
        
        stage = getAttachedStage(obj);
        
        pwrRate = getElectricalPwrRate(obj, elemSet, steeringModel);
        
        newState = createDefaultInitialState(obj, stageState)
        
        useTF = openEditDialog(obj);
        
        tf = isInUse(obj);
        
        newObj = copy(obj);
        
        summStr = getSummaryStr(obj);
    end
    
    methods(Sealed)
        function tf = eq(a,b)
            tf = [a.id] == [b.id];
        end
    end
end