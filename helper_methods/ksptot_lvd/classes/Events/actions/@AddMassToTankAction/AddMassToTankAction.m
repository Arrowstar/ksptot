classdef AddMassToTankAction < AbstractEventAction
    %AddMassToTankAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tank LaunchVehicleTank
        massToAdd(1,1) double = 0;
        
        optVar AbstractOptimizationVariable
    end
    
    methods
        function obj = AddMassToTankAction(tank, massToAdd)
            if(nargin > 0)
                obj.tank = tank;
                obj.massToAdd = massToAdd;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            
            tankStates = newStateLogEntry.getAllTankStates();
            tankState = tankStates([tankStates.tank] == obj.tank);
            tankState.tankMass = max(0, tankState.tankMass + obj.massToAdd);
        end
        
        function initAction(obj, initialStateLogEntry)
            %none
        end
        
        function name = getName(obj)           
            name = sprintf('Add Mass to Tank (%s, %0.3f mT)', obj.tank.name, obj.massToAdd);
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
        end
        
        function tf = usesTank(obj, tank)
            tf = obj.tank == tank;
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
            
            if(not(isempty(obj.optVar)))
                tf = any(obj.optVar.getUseTfForVariable());
                vars(end+1) = obj.optVar;
            end
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
%             addActionTf = lvd_AddMassToTankActionGUI(action, lv.lvdData);
            
            output = AppDesignerGUIOutput({false});
            lvd_AddMassToTankActionGUI_App(action, lv.lvdData, output);
            addActionTf = output.output{1};
        end
    end
end