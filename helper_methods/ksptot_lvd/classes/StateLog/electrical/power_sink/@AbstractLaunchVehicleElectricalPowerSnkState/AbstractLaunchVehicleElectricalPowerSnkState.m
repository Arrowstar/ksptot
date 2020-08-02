classdef(Abstract) AbstractLaunchVehicleElectricalPowerSnkState < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
    %AbstractLaunchVehicleElectricalPowerSrcSnkState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stageState = LaunchVehicleStageState.empty(1,0);
    end
    
    methods
        epsSinkComponent = getEpsSinkComponent(obj)
        
        pwrRate = getElectricalPwrRate(obj, elemSet, steeringModel)
        
        active = getActiveState(obj)
        
        setActiveState(obj,active)
    end
end