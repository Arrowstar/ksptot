classdef SetHoldDownClampActiveStateAction < AbstractEventAction
    %SetStageActiveStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        activeStateToSet(1,1) logical = false;
    end
    
    methods
        function obj = SetHoldDownClampActiveStateAction(activeStateToSet)
            if(nargin > 0)
                obj.activeStateToSet = activeStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();
            newStateLogEntry.lvState.holdDownEnabled = obj.activeStateToSet;
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
            
            name = sprintf('Set Hold Down Clamp State (%s)', tf);
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
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
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_EditActionSetClampStateGUI(action);
        end
    end
end