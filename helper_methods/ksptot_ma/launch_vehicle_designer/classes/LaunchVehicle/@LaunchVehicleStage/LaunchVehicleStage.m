classdef LaunchVehicleStage < matlab.mixin.SetGet
    %LaunchVehicleStage Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        launchVehicle(1,1) LaunchVehicle
        
        engines(1,:) LaunchVehicleEngine
        tanks(1,:) LaunchVehicleTank
        
        dryMass(1,1) double = 0; %mT
    end
    
    methods
        function obj = LaunchVehicleStage(launchVehicle)
            obj.launchVehicle = launchVehicle;
        end
    end
end