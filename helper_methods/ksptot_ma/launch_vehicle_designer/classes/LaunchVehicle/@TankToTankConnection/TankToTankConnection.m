classdef TankToTankConnection < matlab.mixin.SetGet
    %TankToTankConnection Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        srcTank LaunchVehicleTank 
        tgtTank LaunchVehicleTank
    end
    
    properties(Dependent)
        lvdData
    end
    
    methods
        function obj = TankToTankConnection(srcTank, tgtTank)
            if(nargin > 0)
                obj.srcTank = srcTank;
                obj.tgtTank = tgtTank;
            end
        end
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.engine.srcTank.stage.launchVehicle.lvdData;
        end
        
        function nameStr = getName(obj)
            nameStr = sprintf('%s to %s', obj.engine.name, obj.tank.name);
        end
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesEngineToTankConn(obj);
        end        
    end
end