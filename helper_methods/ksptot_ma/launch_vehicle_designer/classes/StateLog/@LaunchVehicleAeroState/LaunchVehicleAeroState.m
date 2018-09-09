classdef LaunchVehicleAeroState < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        area(1,1) double = 1; %m^2
        Cd(1,1) double = 2.2;
    end
    
    methods
        function obj = LaunchVehicleAeroState()
            
        end
        
        function newAeroState = deepCopy(obj)
            newAeroState = LaunchVehicleAeroState();
            
            newAeroState.area = obj.area;
            newAeroState.Cd = obj.Cd;
        end
    end
end