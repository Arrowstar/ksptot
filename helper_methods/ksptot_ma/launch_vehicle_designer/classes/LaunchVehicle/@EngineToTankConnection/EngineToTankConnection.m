classdef EngineToTankConnection < matlab.mixin.SetGet
    %EngineToTankConnection Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tank(1,:) LaunchVehicleTank 
        engine(1,:) LaunchVehicleEngine
    end
    
    properties(Dependent)
        lvdData
    end
    
    methods
        function obj = EngineToTankConnection(tank, engine)
            if(nargin > 0)
                obj.tank = tank;
                obj.engine = engine;
            end
        end
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.engine.stage.launchVehicle.lvdData;
        end
        
        function nameStr = getName(obj)
            nameStr = sprintf('%s to %s', obj.engine.name, obj.tank.name);
        end
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesEngineToTankConn(obj);
        end        
    end
end