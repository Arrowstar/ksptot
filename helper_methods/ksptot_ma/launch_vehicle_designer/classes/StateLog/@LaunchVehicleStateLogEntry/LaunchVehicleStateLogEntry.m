classdef LaunchVehicleStateLogEntry < matlab.mixin.SetGet
    %LaunchVehicleStateLogEntry Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time(1,1) double = 0;
        position(3,1) double = [0;0;0];
        velocity(3,1) double = [0;0;0];
        centralBody(1,1) struct = struct()
        stageStates@LaunchVehicleStageState
        event(1,1)
    end
    
    methods
        function obj = LaunchVehicleStateLogEntry()
            
        end
    end
end