classdef SetTankTankConnFlowRateEventAction < AbstractEventAction
    %SetTankTankConnFlowRateEventAction Summary of this class goes here
    %   Detailed explanation goes here
        
    properties(Abstract=false)
        conn TankToTankConnection
        flowRateToSet(1,1) double = 0;
    end
    
    methods
        function obj = SetTankTankConnFlowRateEventAction(conn, flowRateToSet)
            if(nargin > 0)
                obj.conn = conn;
                obj.flowRateToSet = flowRateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            lvState = newStateLogEntry.lvState;
            connState = lvState.t2TConns([lvState.t2TConns.conn] == obj.conn);
            
            connState.flowRate = obj.flowRateToSet;
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)            
            name = sprintf('Set Tank to Tank Conn. Flow Rate (%s => %.3f mT/s)', obj.conn.getName(), obj.flowRateToSet);
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
%                 addActionTf = lvd_EditActionSetTankToTankConnFlowRateGUI(action, lv);

                output = AppDesignerGUIOutput({false});
                lvd_EditActionSetTankToTankConnFlowRateGUI_App(action, lv, output);
                addActionTf = output.output{1};
            else
                addActionTf = false;
                warndlg('There are no tank to tank connections on the launch vehicle.  Create one first.','Cannot Create Action','modal');
            end
        end
    end
end