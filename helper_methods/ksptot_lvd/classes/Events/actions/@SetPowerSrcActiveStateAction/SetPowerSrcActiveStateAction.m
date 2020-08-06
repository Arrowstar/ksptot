classdef SetPowerSrcActiveStateAction < AbstractEventAction
    %SetPowerSrcActiveStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        src AbstractLaunchVehicleElectricalPowerSrcSnk
        activeStateToSet(1,1) logical = false;
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = SetPowerSrcActiveStateAction(src, activeStateToSet)
            if(nargin > 0)
                obj.src = src;
                obj.activeStateToSet = activeStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry; 
            stageStates = newStateLogEntry.stageStates;

            pwrSrcStates = AbstractLaunchVehicleElectricalPowerSrcState.empty(1,0);
            for(i=1:length(stageStates)) %#ok<*NO4LP>
                pwrSrcStates = horzcat(pwrSrcStates, stageStates(i).powerSrcStates); %#ok<AGROW>
            end

            pwrSrcs = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);
            for(i=1:length(pwrSrcStates))
                pwrSrcs = horzcat(pwrSrcs, pwrSrcStates(i).getEpsSrcComponent()); %#ok<AGROW>
            end

            pwrSrcInd = find(pwrSrcs == obj.src,1,'first');
            pwrSrcState = pwrSrcStates(pwrSrcInd);
            
            pwrSrcState.setActiveState(obj.activeStateToSet);
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
            
            name = sprintf('Set Power Source State (%s = %s)',obj.src.getName(),tf);
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
            tf = false;
        end
        
        function tf = usesPwrSrc(obj, powerSrc)
            tf = [obj.src] == powerSrc;
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
            [~, powerSrcs] = lv.getPowerSrcsListBoxStr();
            
            if(not(isempty(powerSrcs)))
                addActionTf = lvd_EditActionSetPwrSrcStateGUI(action, lv);
            else
                addActionTf = false;
                warndlg('There are no power sources on the vehicle.  Create one first.','Cannot Create Action','modal');
            end
        end
    end
end