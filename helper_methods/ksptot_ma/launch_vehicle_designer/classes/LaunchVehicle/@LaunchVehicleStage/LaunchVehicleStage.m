classdef LaunchVehicleStage < matlab.mixin.SetGet
    %LaunchVehicleStage Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        engines@LaunchVehicleEngine
        tanks@LaunchVehicleTank
        
        dryMass(1,1) double = 0; %mT
    end
    
    methods
        function obj = LaunchVehicleStage()
            
        end
    end
end