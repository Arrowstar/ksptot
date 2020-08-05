classdef(Abstract) AbstractLaunchVehicleElectricalPowerStorage < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractLaunchVehicleElectricalPowerStorage Summary of this class goes here
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
        
        newState = createDefaultInitialState(obj, stageState)
        
        useTF = openEditDialog(obj);
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesPwrStorage(obj);
        end
        
        newObj = copy(obj);
        
        summStr = getSummaryStr(obj);
        
        maxCapacity = getMaximumCapacity(obj);
        
        initialStateOfCharge = getInitialStateOfCharge(obj);
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.getAttachedStage().launchVehicle.lvdData;
        end
    end
end