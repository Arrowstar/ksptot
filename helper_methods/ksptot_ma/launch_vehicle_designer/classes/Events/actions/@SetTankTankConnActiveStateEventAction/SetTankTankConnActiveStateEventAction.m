classdef SetTankTankConnActiveStateEventAction < AbstractEventAction
    %SetTankTankConnActiveStateEventAction Summary of this class goes here
    %   Detailed explanation goes here
        
    properties(Abstract=false)
        conn TankToTankConnection
        activeStateToSet(1,1) logical = true;
    end
    
    methods
        function obj = SetTankTankConnActiveStateEventAction(conn, activeStateToSet)
            if(nargin > 0)
                obj.conn = conn;
                obj.activeStateToSet = activeStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            lvState = newStateLogEntry.lvState;
            connState = lvState.t2TConns([lvState.t2TConns.conn] == obj.conn);
            
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
            
            name = sprintf('Set Tank to Tank Conn. State (%s = %s)', obj.conn.getName(), tf);
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
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = ([obj.conn] == tankToTank);
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            if(not(isempty(lv.tankToTankConns)))
                addActionTf = lvd_EditActionSetTankToTankConnStateGUI(action, lv);
            else
                addActionTf = false;
                warndlg('There are no tank to tank connections on the launch vehicle.  Create one first.','Cannot Create Action','modal');
            end
        end
    end
end