classdef LaunchVehicleAeroState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %drag
        area(1,1) double = 1; %m^2
        Cd(1,1) double = 0.3;
        
        %lift
        useLift(1,1) logical = false;
        areaLift(1,1) double = 16.2; 
        Cl_0(1,1) double = 0.731;  
        bodyLiftVect(3,1) double = [0;0;-1];
    end
    
    methods
        function obj = LaunchVehicleAeroState()
            
        end
        
        function newAeroState = deepCopy(obj)
            newAeroState = obj.copy();
        end
    end
end