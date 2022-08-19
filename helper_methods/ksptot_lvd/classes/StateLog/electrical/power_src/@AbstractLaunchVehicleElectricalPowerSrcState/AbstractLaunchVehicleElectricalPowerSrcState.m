classdef(Abstract) AbstractLaunchVehicleElectricalPowerSrcState < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
    %AbstractLaunchVehicleElectricalPowerSrc Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stageState = LaunchVehicleStageState.empty(1,0)
    end
    
    methods
        epsSrcComponent = getEpsSrcComponent(obj)
        
        pwrRate = getElectricalPwrRate(obj, elemSet, steeringModel, hasSunLoS, body2InertDcm, elemSetSun);
        
        active = getActiveState(obj)
        
        setActiveState(obj,active)
    end
end