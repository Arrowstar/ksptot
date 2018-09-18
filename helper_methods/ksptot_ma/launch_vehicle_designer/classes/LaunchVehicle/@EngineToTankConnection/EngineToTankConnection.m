classdef EngineToTankConnection < matlab.mixin.SetGet
    %EngineToTankConnection Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tank(1,1) LaunchVehicleTank = LaunchVehicleTank(LaunchVehicleStage(LaunchVehicle(LvdData.getEmptyLvdData())))
        engine(1,1) LaunchVehicleEngine = LaunchVehicleEngine(LaunchVehicleStage(LaunchVehicle(LvdData.getEmptyLvdData())))
    end
    
    methods
        function obj = EngineToTankConnection(tank, engine)
            if(nargin > 0)
                obj.tank = tank;
                obj.engine = engine;
            end
        end
        
        function nameStr = getName(obj)
            nameStr = sprintf('%s to %s', obj.engine.name, obj.tank.name);
        end
    end
end