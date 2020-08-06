classdef SetPowerSinkActiveStateAction < AbstractEventAction
    %SetPowerSinkActiveStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sink AbstractLaunchVehicleElectricalPowerSrcSnk
        activeStateToSet(1,1) logical = false;
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = SetPowerSinkActiveStateAction(sink, activeStateToSet)
            if(nargin > 0)
                obj.sink = sink;
                obj.activeStateToSet = activeStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;            
            stageStates = newStateLogEntry.stageStates;
            
            pwrSinkStates = AbstractLaunchVehicleElectricalPowerSnkState.empty(1,0);
            for(i=1:length(stageStates)) %#ok<*NO4LP>
                pwrSinkStates = horzcat(pwrSinkStates, stageStates(i).powerSinkStates); %#ok<AGROW>
            end

            pwrSinks = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);
            for(i=1:length(pwrSinkStates))
                pwrSinks = horzcat(pwrSinks, pwrSinkStates(i).getEpsSinkComponent()); %#ok<AGROW>
            end

            pwrSinkInd = find(pwrSinks == obj.sink,1,'first');
            pwrSinkState = pwrSinkStates(pwrSinkInd);
            
            pwrSinkState.setActiveState(obj.activeStateToSet);
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
            
            name = sprintf('Set Power Sink State (%s = %s)',obj.sink.getName(),tf);
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

        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
        end
        
        function tf = usesPwrSink(obj, powerSink)
            tf = [obj.sink] == powerSink;
        end
        
        function tf = usesPwrSrc(obj, powerSrc)
            tf = false;
        end
        
        function tf = usesPwrStorage(obj, powerStorage)
            tf = false;
        end
        
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = obj.emptyVarArr;
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            [~, powerSinks] = lv.getPowerSinksListBoxStr();
            
            if(not(isempty(powerSinks)))
                addActionTf = lvd_EditActionSetPwrSinkStateGUI(action, lv);
            else
                addActionTf = false;
                warndlg('There are no power sinks on the vehicle.  Create one first.','Cannot Create Action','modal');
            end
        end
    end
end