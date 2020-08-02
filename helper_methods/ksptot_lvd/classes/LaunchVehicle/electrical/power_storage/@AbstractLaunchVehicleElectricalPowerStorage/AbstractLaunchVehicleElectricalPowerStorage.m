classdef(Abstract) AbstractLaunchVehicleElectricalPowerStorage < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractLaunchVehicleElectricalPowerStorage Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        name = getName(obj);
        
        stage = getAttachedStage(obj);
        
        newState = createDefaultInitialState(obj, stageState)
        
        useTF = openEditDialog(obj);
        
        tf = isInUse(obj);
        
        newObj = copy(obj);
        
        summStr = getSummaryStr(obj);
        
        maxCapacity = getMaximumCapacity(obj);
        
        initialStateOfCharge = getInitialStateOfCharge(obj);
    end
end