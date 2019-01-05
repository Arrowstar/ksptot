classdef SetStageActiveStateAction < AbstractEventAction
    %SetStageActiveStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage(1,:) LaunchVehicleStage
        activeStateToSet(1,1) logical = false;
    end
    
    methods
        function obj = SetStageActiveStateAction(stage, activeStateToSet)
            if(nargin > 0)
                obj.stage = stage;
                obj.activeStateToSet = activeStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            
            stgState = newStateLogEntry.stageStates([newStateLogEntry.stageStates.stage] == obj.stage);
            stgState.active = obj.activeStateToSet;
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)
            if(obj.activeStateToSet)
                tf = 'Active';
            else
                tf = 'Inactive';
            end
            
            name = sprintf('Set Stage State (%s = %s)', obj.stage.name, tf);
        end
        
        function tf = usesStage(obj, stage)
            tf = ([obj.stage] == stage);
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_EditActionSetStageStateGUI(action, lv);
        end
    end
end