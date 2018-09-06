classdef EngineToTankConnection < matlab.mixin.SetGet
    %EngineToTankConnection Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tank(1,1) LaunchVehicleTank
        engine(1,1) LaunchVehicleEngine
    end
    
    methods
        function obj = EngineToTankConnection(tank, engine)
            obj.tank = tank;
            obj.engine = engine;
        end
    end
end