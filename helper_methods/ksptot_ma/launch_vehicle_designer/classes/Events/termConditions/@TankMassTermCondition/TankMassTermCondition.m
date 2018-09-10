classdef TankMassTermCondition < AbstractEventTerminationCondition
    %TankMassTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tank(1,1) LaunchVehicleTank = LaunchVehicleTank(LaunchVehicleStage(LaunchVehicle()));
        targetMass(1,1) double = 0;
        tankStateInd(1,1) double = 1;
    end
    
    methods
        function obj = TankMassTermCondition(tank,targetMass)
            obj.tank = tank;
            obj.targetMass = targetMass;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, obj.tankStateInd, obj.targetMass);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            tankStates = initialStateLogEntry.getAllTankStates();
            obj.tankStateInd = find([tankStates.tank] == obj.tank);
        end
        
        function name = getName(obj)
            name = 'Tank Mass';
        end
    end
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(t,y, tankStateInd, targetMass)
            value = y(6+tankStateInd) - targetMass;
            isterminal = 1;
            direction = 0;
        end
    end
end