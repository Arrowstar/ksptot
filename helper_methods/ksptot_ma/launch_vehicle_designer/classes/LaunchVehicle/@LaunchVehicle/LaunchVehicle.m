classdef LaunchVehicle < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stages@LaunchVehicleStage
        engineTankConns@EngineToTankConnection
    end
    
    methods
        function obj = LaunchVehicle()
            
        end
    end
end