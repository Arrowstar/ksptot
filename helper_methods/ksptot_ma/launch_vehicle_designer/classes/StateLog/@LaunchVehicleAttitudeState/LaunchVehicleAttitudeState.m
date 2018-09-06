classdef LaunchVehicleAttitudeState < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dcm(3,3) double = eye(3)
    end
    
    methods
        function obj = LaunchVehicleAttitudeState()
            
        end
    end
end