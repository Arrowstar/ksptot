classdef LaunchVehicleEvent < matlab.mixin.SetGet
    %LaunchVehicleEvent Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        termCond(1,1) AbstractEventTerminationCondition = EventDurationTermCondition(0);
        actions AbstractEventAction
        
        name char = 'Untitled Event';
        script LaunchVehicleScript
        
        colorLineSpec(1,1) EventColorLineSpec 
        
        integrator(1,1) IntegratorEnum = IntegratorEnum.ODE45;
        integrationStep(1,1) double = -1;
        checkForSoITrans(1,1) logical = true;
        
        forceModels ForceModelsEnum = ForceModelsEnum.getDefaultArrayOfForceModelEnums();
        
        disableOptim(1,1) logical = false;
    end
    
    properties(Dependent)
        lvdData LvdData
    end
    
    methods
        function obj = LaunchVehicleEvent(script)
            obj.script = script;
            obj.colorLineSpec = EventColorLineSpec();
            obj.integrator = IntegratorEnum.ODE45;
        end
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.script.lvdData;
        end
        
        function addAction(obj, newAction)
            obj.actions(end+1) = newAction;
        end
        
        function removeAction(obj, action)
            obj.actions([obj.actions] == action) = [];
        end
        
        function removeActionByInd(obj, ind)
            if(ind >= 1 && ind <= length(obj.actions))
                obj.removeAction(obj.actions(ind));
            end
        end
        
        function action = getActionForInd(obj, ind)
            action = AbstractEventAction.empty(1,0);
            
            if(ind >= 1 && ind <= length(obj.actions))
                action = obj.actions(ind);
            end
        end
        
        function evtNum = getEventNum(obj)
            evtNum = obj.script.getNumOfEvent(obj);
        end
        
        function listboxStr = getListboxStr(obj)
            hasOpt = obj.hasActiveOptVars();
            if(obj.disableOptim == true)
                optStr = '**';
            elseif(hasOpt && obj.disableOptim == false)
                optStr = '*';
            else
                optStr = '';
            end
            
            listboxStr = sprintf('%i - %s%s', obj.getEventNum(), optStr, obj.name);
        end
        
        function [aListboxStr, actions] = getActionsListboxStr(obj)
            aListboxStr = {};
            actions = AbstractEventAction.empty(0,1);
            
            for(i=1:length(obj.actions)) %#ok<*NO4LP>
                aListboxStr{end+1} = obj.actions(i).getName(); %#ok<AGROW>
                actions(end+1) = obj.actions(i); %#ok<AGROW>
            end
        end
        
        function initEvent(obj, initialStateLogEntry)
            obj.termCond.initTermCondition(initialStateLogEntry);
        end
        
        function initEventOnRestart(obj, initialStateLogEntry)
            if(obj.termCond.shouldBeReinitOnRestart())
                obj.initEvent(initialStateLogEntry);
            end
        end
        
        function newStateLogEntries = cleanupEvent(obj, finalStateLogEntry)
            for(i=1:length(obj.actions)) %#ok<*NO4LP>
                obj.actions(i).initAction(finalStateLogEntry);
            end
            
            newStateLogEntries = LaunchVehicleStateLogEntry.empty(1,0);
            for(i=1:length(obj.actions))
                newStateLogEntry = obj.actions(i).executeAction(finalStateLogEntry);
                
                newStateLogEntries(end+1) = newStateLogEntry; %#ok<AGROW>
                finalStateLogEntry = newStateLogEntry;
            end
        end
        
        function newStateLogEntries = executeEvent(obj, initStateLogEntry, simDriver, tStartPropTime, tStartSimTime, isSparseOutput, activeNonSeqEvts)
            if(isempty(obj.integrator))
                obj.integrator = IntegratorEnum.ODE45;
            end
            [newStateLogEntries] = simDriver.integrateOneEvent(obj, initStateLogEntry, obj.integrator, tStartPropTime, tStartSimTime, isSparseOutput, obj.checkForSoITrans, activeNonSeqEvts, obj.forceModels);
        end
        
        function tf = usesStage(obj, stage)
            tf = obj.termCond.usesStage(stage);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesStage(stage);
            end
        end
        
        function tf = usesEngine(obj, engine)
            tf = obj.termCond.usesEngine(engine);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesEngine(engine);
            end
        end
        
        function tf = usesTank(obj, tank)
            tf = obj.termCond.usesTank(tank);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesTank(tank);
            end
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = obj.termCond.usesEngineToTankConn(engineToTank);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesEngineToTankConn(engineToTank);
            end
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = obj.termCond.usesStopwatch(stopwatch);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesStopwatch(stopwatch);
            end
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesExtremum(extremum);
            end
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesTankToTankConn(tankToTank);
            end
        end
        
        function toggleOptimDisable(obj, lvdData)
            obj.disableOptim = not(obj.disableOptim);
            
            lvdData.optimizer.vars.clearCachedVarEvtDisabledStatus();
        end
        
        function [tf, vars] = hasActiveOptVars(obj)
            tf = false;
            
            vars = AbstractOptimizationVariable.empty(0,1);
            
            tcOptVar = obj.termCond.getExistingOptVar();
            if(not(isempty(tcOptVar)))
                tf = any(tcOptVar.getUseTfForVariable());
                
                vars(end+1) = tcOptVar;
            end
            
            for(i=1:length(obj.actions))
                [aTf, aVars] = obj.actions(i).hasActiveOptimVar();
                tf = tf || aTf;
                
                if(isempty(vars))
                    vars = aVars;
                else
                    vars = horzcat(vars, aVars); %#ok<AGROW>
                end
            end
        end
    end
    
    methods(Static)
        function newEvent = getDefaultEvent(script)
            newEvent = LaunchVehicleEvent(script);
            newEvent.termCond = EventDurationTermCondition(0);
        end
    end
end

