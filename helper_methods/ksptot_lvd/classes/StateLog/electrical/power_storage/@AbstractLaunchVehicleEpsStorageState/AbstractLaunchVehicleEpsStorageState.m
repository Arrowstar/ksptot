classdef(Abstract) AbstractLaunchVehicleEpsStorageState < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
    %AbstractLaunchVehicleElectricalPowerStorageState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        stateOfCharge = getStateOfCharge(obj)
        
        setStateOfCharge(obj, stateOfCharge)
        
        epsStorageComponent = getEpsStorageComponent(obj)
        
        active = getActiveState(obj)
        
        setActiveState(obj,active)
    end
end