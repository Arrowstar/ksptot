classdef SetEngineTankConnActiveStateEventAction < AbstractEventAction
    %AbstractEventAction Summary of this class goes here
    %   Detailed explanation goes here
        
    properties(Abstract=false)
        conn(1,:) EngineToTankConnection
        activeStateToSet(1,1) logical = true;
    end
    
    methods
        function obj = SetEngineTankConnActiveStateEventAction(conn, activeStateToSet)
            if(nargin > 0)
                obj.conn = conn;
                obj.activeStateToSet = activeStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();
            lvState = newStateLogEntry.lvState;
            connState = lvState.e2TConns([lvState.e2TConns.conn] == obj.conn);
            
            connState.active = obj.activeStateToSet;
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
            
            name = sprintf('Set Eng to Tank Conn. State (%s = %s)', obj.conn.getName(), tf);
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
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = ([obj.conn] == engineToTank);
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_EditActionSetEngineToTankConnStateGUI(action, lv);
        end
    end
end