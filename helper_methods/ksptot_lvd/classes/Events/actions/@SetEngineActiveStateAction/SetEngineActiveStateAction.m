classdef SetEngineActiveStateAction < AbstractEventAction
    %SetEngineActiveStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        engine LaunchVehicleEngine
        activeStateToSet(1,1) logical = false;
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = SetEngineActiveStateAction(engine, activeStateToSet)
            if(nargin > 0)
                obj.engine = engine;
                obj.activeStateToSet = activeStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            stage = obj.engine.stage;
            
            stgState = newStateLogEntry.stageStates([newStateLogEntry.stageStates.stage] == stage);
            
            engineState = stgState.engineStates([stgState.engineStates.engine] == obj.engine);
            engineState(1).active = obj.activeStateToSet;
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
            
            name = sprintf('Set Engine State (%s = %s)',obj.engine.name,tf);
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
        end
        
        function tf = usesEngine(obj, engine)
            tf = ([obj.engine] == engine);
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
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = obj.emptyVarArr;
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
%             addActionTf = lvd_EditActionSetEngineStateGUI(action, lv);
            
            output = AppDesignerGUIOutput({false});
            lvd_EditActionSetEngineStateGUI_App(action, lv, output);
            addActionTf = output.output{1};
        end
    end
end