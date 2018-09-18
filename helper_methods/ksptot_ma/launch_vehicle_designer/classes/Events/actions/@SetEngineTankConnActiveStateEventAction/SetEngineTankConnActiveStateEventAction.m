classdef SetEngineTankConnActiveStateEventAction < AbstractEventAction
    %AbstractEventAction Summary of this class goes here
    %   Detailed explanation goes here
        
    properties(Abstract=false)
        conn(1,1) EngineToTankConnection
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
        
        function newStateLogEntry = exectuteAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();
            lvState = newStateLogEntry.lvState;
            connState = lvState.e2TConns([lvState.e2TConns] == obj.conn);
            
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
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_EditActionSetEngineToTankConnStateGUI(action, lv);
        end
    end
end