classdef LaunchVehicleEngineState < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        engine(1,1) LaunchVehicleEngine
        
        active(1,1) logical = false;
    end
    
    methods
        function obj = LaunchVehicleTankState()
            
        end
    end
end