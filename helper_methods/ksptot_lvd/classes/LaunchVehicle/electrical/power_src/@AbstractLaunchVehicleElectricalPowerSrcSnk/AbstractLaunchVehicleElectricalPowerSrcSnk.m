classdef(Abstract) AbstractLaunchVehicleElectricalPowerSrcSnk < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractLaunchVehicleElectricalPowerSrc Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Abstract)
        id
    end
    
    properties(Dependent)
        lvdData
    end
    
    methods
        name = getName(obj);
        
        stage = getAttachedStage(obj);
        
        pwrRate = getElectricalPwrRate(obj, elemSet, steeringModel, hasSunLoS, body2InertDcm, elemSetSun);
        
        newState = createDefaultInitialState(obj, stageState)
        
        useTF = openEditDialog(obj);
        
        tf = isInUse(obj);
        
        newObj = copy(obj);
        
        summStr = getSummaryStr(obj);
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.getAttachedStage().launchVehicle.lvdData;
        end
    end
    
    methods(Sealed)
        function tf = eq(a,b)
            tf = [a.id] == [b.id];
        end
    end
end