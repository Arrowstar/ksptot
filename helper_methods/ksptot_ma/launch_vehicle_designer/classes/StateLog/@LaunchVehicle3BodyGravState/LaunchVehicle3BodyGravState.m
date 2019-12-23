classdef LaunchVehicle3BodyGravState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicle3BodyGravState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodies KSPTOT_BodyInfo %an array of bodies
        celBodyData struct
    end
    
    methods
        function obj = LaunchVehicle3BodyGravState()
            
        end
    end
end