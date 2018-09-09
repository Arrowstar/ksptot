classdef LaunchVehicleTank < matlab.mixin.SetGet
    %LaunchVehicleTank Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage(1,1) LaunchVehicleStage = LaunchVehicleStage(LaunchVehicle());
        
        initialMass(1,1) double = 0; %mT
        
        id(1,1) double = 0;
    end
    
    methods
        function obj = LaunchVehicleTank(stage)
            obj.stage = stage;
            obj.id = rand();
        end
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
        end
    end
end