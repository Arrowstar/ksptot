classdef TankMassTermCondition < AbstractEventTerminationCondition
    %TankMassTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tank(1,1) LaunchVehicleTank = LaunchVehicleTank(LaunchVehicleStage(LaunchVehicle(LvdData.getEmptyLvdData())));
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
            name = sprintf('Tank Mass (%s = %0.3f mT)', obj.tank.name, obj.targetMass);
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Target Mass';
            params.paramUnit = 'mT';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'on';
            params.useEngines = 'off';
            
            params.value = obj.targetMass;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = obj.tank;
            params.refEngine = LaunchVehicleEngine.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = TankMassOptimizationVariable(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end
    end
    
    methods(Static)
        function termCond = getTermCondForParams(paramValue, stage, tank, engine)
            termCond = TankMassTermCondition(tank,paramValue);
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