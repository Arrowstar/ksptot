classdef LaunchVehicleStage < matlab.mixin.SetGet
    %LaunchVehicleStage Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        launchVehicle(1,1) LaunchVehicle
        
        name(1,:) char = 'Untitled Stage';
        engines(1,:) LaunchVehicleEngine
        tanks(1,:) LaunchVehicleTank
        
        dryMass(1,1) double = 0; %mT
        
        id(1,1) double = 0;
    end
    
    methods
        function obj = LaunchVehicleStage(launchVehicle)
            obj.launchVehicle = launchVehicle;
            obj.id = rand();
        end
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
        end
    end
end