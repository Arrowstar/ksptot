classdef SetKinematicStateAction < AbstractEventAction
    %SetTimePositionVelocityMassStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stateLog LaunchVehicleStateLog
        orbitModel(1,1) AbstractElementSet = KeplerianElementSet.getDefaultElements();
        
        %Inherit Time
        inheritTime(1,1) logical = false;
        inheritTimeFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritTimeFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0);
        
        %Inherit State
        inheritPosVel(1,1) logical = false;
        inheritPosVelFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritPosVelFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0);
        
        %Inherit Stage States
        stageStates(1,:) SetKinematicStateStageState 
        engineStates(1,:) SetKinematicStateEngineState
        tankStates(1,:) SetKinematicStateTankState
        epsSinkStates(1,:) SetKinematicStateEPSinkState
        epsSrcStates(1,:) SetKinematicStateEPSrcState
        epsStorageStates(1,:) SetKinematicStateEPStorageState
        
        %Inherit all other state elements
        inheritStateElems(1,1) logical = true;
        inheritStateElemsFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritStateElemsFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0);
        
        optVar SetKinematicStateActionVariable
    end
    
    %deprecated
    properties
        inheritStageStates(1,1) logical = true;
        inheritStageStatesFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritStageStatesFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0);
    end
    
    properties(Dependent)
        time(1,1) double
        centralBody(1,1) KSPTOT_BodyInfo
    end
    
    methods
        function obj = SetKinematicStateAction(stateLog, orbitModel)
            if(nargin > 0)
                obj.stateLog = stateLog;
                obj.orbitModel = orbitModel;
            end
            
            obj.id = rand();
        end
        
        function time = get.time(obj)
            time = obj.orbitModel.time;
        end
        
        function set.time(obj, newTime)
            obj.orbitModel.time = newTime;
        end
        
        function time = get.centralBody(obj)
            time = obj.orbitModel.frame.getOriginBody();
        end
        
        function set.centralBody(obj, newCentralBody)
            obj.orbitModel.frame.setOriginBody(newCentralBody);
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();

            % Time
            if(obj.inheritTime)
                if(obj.inheritTimeFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritTimeFromEvent)) && ...
                   not(isempty(obj.inheritTimeFromEvent.getEventNum())) && ...
                   obj.inheritTimeFromEvent.getEventNum() > 0)
               
                    timeEvtStateLog = obj.stateLog.getLastStateLogForEvent(obj.inheritTimeFromEvent);
                    if(not(isempty(timeEvtStateLog)))
                        newStateLogEntry.time = timeEvtStateLog(end).time;
                        obj.orbitModel.time = newStateLogEntry.time;
                    end
                end
            else
                newStateLogEntry.time = obj.orbitModel.time;
            end
            
            % Orbit
            if(obj.inheritPosVel)
                if(obj.inheritPosVelFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritPosVelFromEvent)) && ...
                   not(isempty(obj.inheritPosVelFromEvent.getEventNum())) && ...
                   obj.inheritPosVelFromEvent.getEventNum() > 0)
               
                    posVelEvtStateLog = obj.stateLog.getLastStateLogForEvent(obj.inheritPosVelFromEvent);
                    if(not(isempty(posVelEvtStateLog)))
                        newStateLogEntry.position = posVelEvtStateLog(end).position;
                        newStateLogEntry.velocity = posVelEvtStateLog(end).velocity;
                        newStateLogEntry.centralBody = posVelEvtStateLog(end).centralBody;
                    end
                end
            else
                cartElemSet = obj.orbitModel.convertToCartesianElementSet();
                
                newStateLogEntry.setCartesianElementSet(cartElemSet);
            end
            

            for(i=1:length(obj.stageStates)) %#ok<*UNRCH>
                obj.stageStates(i).updateStateLogEntry(newStateLogEntry, obj.stateLog)
            end

            for(i=1:length(obj.engineStates))
                obj.engineStates(i).updateStateLogEntry(newStateLogEntry, obj.stateLog)
            end

            for(i=1:length(obj.tankStates))
                obj.tankStates(i).updateStateLogEntry(newStateLogEntry, obj.stateLog)
            end

            for(i=1:length(obj.epsSinkStates))
                obj.epsSinkStates(i).updateStateLogEntry(newStateLogEntry, obj.stateLog)
            end

            for(i=1:length(obj.epsSrcStates))
                obj.epsSrcStates(i).updateStateLogEntry(newStateLogEntry, obj.stateLog)
            end

            for(i=1:length(obj.epsStorageStates))
                obj.epsStorageStates(i).updateStateLogEntry(newStateLogEntry, obj.stateLog)
            end


            %Comment out this block once done
%             if(obj.inheritStageStates)
%                 if(obj.inheritStageStatesFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
%                    not(isempty(obj.inheritStageStatesFromEvent)) && ...
%                    not(isempty(obj.inheritStageStatesFromEvent.getEventNum())) && ...
%                    obj.inheritStageStatesFromEvent.getEventNum() > 0)
%                
%                
%                     stageStateEvtState = obj.stateLog.getLastStateLogForEvent(obj.inheritStageStatesFromEvent);
%                     stageStateEvtState = stageStateEvtState(end);
%                     if(not(isempty(stageStateEvtState)))
%                         lvState = stageStateEvtState.lvState.deepCopy();
%                         newStateLogEntry.lvState = lvState;
%                         
%                         for(i=1:length(stageStateEvtState.stageStates)) %#ok<NO4LP>
%                             newStateLogEntry.stageStates(i) = stageStateEvtState.stageStates(i).deepCopy(true, lvState);
%                         end
%                     end
%                 end
%                 
%             else
%                 %do nothing, there is no behavior for this yet
%                 warning('SetKinematicStateAction.inheritStageStates must be set to true, no behavior yet defined when this is set to false.');
%             end
            
            %Misc states
            if(obj.inheritStateElems)
              if(obj.inheritStateElemsFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritStateElemsFromEvent)) && ...
                   not(isempty(obj.inheritStateElemsFromEvent.getEventNum())) && ...
                   obj.inheritStateElemsFromEvent.getEventNum() > 0)
               
                    stateElemsEvtState = obj.stateLog.getLastStateLogForEvent(obj.inheritStateElemsFromEvent);
                    
                    if(not(isempty(stateElemsEvtState)))
                        stateElemsEvtState = stateElemsEvtState(end);

                        newStateLogEntry.aero = stateElemsEvtState.aero.deepCopy();
                        newStateLogEntry.thirdBodyGravity = stateElemsEvtState.thirdBodyGravity.copy();
                        newStateLogEntry.stopwatchStates = stateElemsEvtState.stopwatchStates.copy();
                        newStateLogEntry.extremaStates = stateElemsEvtState.extremaStates.copy();
                        newStateLogEntry.steeringModel = stateElemsEvtState.steeringModel; %NEED TO WARN USE TO REINITIALIZE THROTTLE AND STEERING MODELS!
                        newStateLogEntry.throttleModel = stateElemsEvtState.throttleModel;
                    end
              end
            else
                %do nothing, there is no behavior for this yet
                warning('SetKinematicStateAction.inheritStateElems must be set to true, no behavior yet defined when this is set to false.');
            end
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)
            name = 'Set Kinematic State';
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
        
        function tf = usesEvent(obj, event)
            tf = false;
            
            tankEvtsTf = logical([]);
            for(i=1:length(obj.tankStates))
                tankState = obj.tankStates(i);
                if(tankState.inheritTankStateFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(tankState.inheritTankStateFromEvent)) && tankState.inheritTankStateFromEvent == event)
                    tankEvtsTf(end+1) = tankState.inheritTankStateFromEvent == event; %#ok<AGROW>
                end
            end

            epsSrcEvtsTf = logical([]);
            for(i=1:length(obj.epsStorageStates))
                storageState = obj.epsStorageStates(i);
                
                if(storageState.inheritStorageStateFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(storageState.inheritStorageStateFromEvent)) && storageState.inheritStorageStateFromEvent == event)
                    epsSrcEvtsTf(end+1) = storageState.inheritStorageStateFromEvent == event; %#ok<AGROW>
                end
            end
            
            if((obj.inheritTime && obj.inheritTimeFrom == InheritStateEnum.InheritFromSpecifiedEvent && not(isempty(obj.inheritTimeFromEvent)) && obj.inheritTimeFromEvent == event) || ...
               (obj.inheritPosVel && obj.inheritPosVelFrom == InheritStateEnum.InheritFromSpecifiedEvent && not(isempty(obj.inheritPosVelFromEvent)) && obj.inheritPosVelFromEvent == event) || ...
               (obj.inheritStateElems && obj.inheritStateElemsFrom == InheritStateEnum.InheritFromSpecifiedEvent && not(isempty(obj.inheritStateElemsFromEvent)) && obj.inheritStateElemsFromEvent == event) || ...
               any(tankEvtsTf) || any(epsSrcEvtsTf))
                tf = true;
            end
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
            
            if(not(isempty(obj.optVar)))
                tf = any(obj.optVar.getUseTfForVariable());
                vars(end+1) = obj.optVar;
            end
        end
        
        function generateLvComponentElements(obj)
            lvdData = obj.event.lvdData;
            
            if(isempty(obj.stageStates))
                stages = lvdData.launchVehicle.stages;
                for(j=1:length(stages))                    
                    stageState = SetKinematicStateStageState(stages(j));
                    stageState.inheritStageState = obj.inheritStageStates;
                    stageState.inheritStageStateFrom = obj.inheritStageStatesFrom;
                    stageState.inheritStageStateFromEvent = obj.inheritStageStatesFromEvent;

                    obj.stageStates(j) = stageState;
                end
            end
            addlistener(lvdData.launchVehicle, 'StageAdded',   @(src, evt) stageAddedClbk(obj, src, evt));
            addlistener(lvdData.launchVehicle, 'StageDeleted', @(src, evt) stageDeletedClbk(obj, src, evt));
            
            
            if(isempty(obj.engineStates))
                [~, engines] = lvdData.launchVehicle.getEnginesListBoxStr();
                for(j=1:length(engines))
                    engineState = SetKinematicStateEngineState(engines(j));
                    engineState.inheritEngineState = obj.inheritStageStates;
                    engineState.inheritEngineStateFrom = obj.inheritStageStatesFrom;
                    engineState.inheritEngineStateFromEvent = obj.inheritStageStatesFromEvent;

                    obj.engineStates(j) = engineState;
                end
            end
            addlistener(lvdData.launchVehicle, 'EngineAdded',   @(src, evt) engineAddedClbk(obj, src, evt));
            addlistener(lvdData.launchVehicle, 'EngineDeleted', @(src, evt) engineDeletedClbk(obj, src, evt));

            if(isempty(obj.tankStates))
                [~, storages] = lvdData.launchVehicle.getTanksListBoxStr();
                for(j=1:length(storages))
                    tankState = SetKinematicStateTankState(storages(j));
                    tankState.inheritTankState = obj.inheritStageStates;
                    tankState.inheritTankStateFrom = obj.inheritStageStatesFrom;
                    tankState.inheritTankStateFromEvent = obj.inheritStageStatesFromEvent;

                    obj.tankStates(j) = tankState;
                end
            end
            addlistener(lvdData.launchVehicle, 'TankAdded',   @(src, evt) tankAddedClbk(obj, src, evt));
            addlistener(lvdData.launchVehicle, 'TankDeleted', @(src, evt) tankDeletedClbk(obj, src, evt));

            if(isempty(obj.epsSinkStates))
                [~, sinks] = lvdData.launchVehicle.getPowerSinksListBoxStr();
                for(j=1:length(sinks))
                    sinkState = SetKinematicStateEPSinkState(sinks(j));
                    sinkState.inheritSinkState = obj.inheritStageStates;
                    sinkState.inheritSinkStateFrom = obj.inheritStageStatesFrom;
                    sinkState.inheritSinkStateFromEvent = obj.inheritStageStatesFromEvent;

                    obj.epsSinkStates(j) = sinkState;
                end
            end
            addlistener(lvdData.launchVehicle, 'EpsSinkAdded',   @(src, evt) epsSinkAddedClbk(obj, src, evt));
            addlistener(lvdData.launchVehicle, 'EpsSinkDeleted', @(src, evt) epsSinkDeletedClbk(obj, src, evt));

            if(isempty(obj.epsSrcStates))
                [~, srcs] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
                for(j=1:length(srcs))
                    srcState = SetKinematicStateEPSrcState(srcs(j));
                    srcState.inheritSrcState = obj.inheritStageStates;
                    srcState.inheritSrcStateFrom = obj.inheritStageStatesFrom;
                    srcState.inheritSrcStateFromEvent = obj.inheritStageStatesFromEvent;

                    obj.epsSrcStates(j) = srcState; 
                end
            end
            addlistener(lvdData.launchVehicle, 'EpsSrcAdded',   @(src, evt) epsSrcAddedClbk(obj, src, evt));
            addlistener(lvdData.launchVehicle, 'EpsSrcDeleted', @(src, evt) epsSrcDeletedClbk(obj, src, evt));
            
            if(isempty(obj.epsStorageStates))
                [~, storages] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
                for(j=1:length(storages))
                    storageState = SetKinematicStateEPStorageState(storages(j));
                    storageState.inheritStorageState = obj.inheritStageStates;
                    storageState.inheritStorageStateFrom = obj.inheritStageStatesFrom;
                    storageState.inheritStorageStateFromEvent = obj.inheritStageStatesFromEvent;

                    obj.epsStorageStates(j) = storageState;
                end
            end
            addlistener(lvdData.launchVehicle, 'EpsStorageAdded',   @(src, evt) epsStorageAddedClbk(obj, src, evt));
            addlistener(lvdData.launchVehicle, 'EpsStorageDeleted', @(src, evt) epsStorageDeletedClbk(obj, src, evt));
            
        end
    end

    methods(Access=private)
        function stageAddedClbk(obj, src, evt)
            stage = evt.stage;
            
            stageState = SetKinematicStateStageState(stage);
            obj.stageStates(end+1) = stageState;
        end
        
        function stageDeletedClbk(obj, src, evt)
            stage = evt.stage;

            obj.stageStates([obj.stageStates.stage] == stage) = [];
        end

        function engineAddedClbk(obj, src, evt)
            engine = evt.engine;
            
            engineState = SetKinematicStateEngineState(engine);
            obj.engineStates(end+1) = engineState;            
        end
        
        function engineDeletedClbk(obj, src, evt)
            engine = evt.engine;
            
            obj.engineStates([obj.engineStates.engine] == engine) = [];
        end
        
        function tankAddedClbk(obj, src, evt)
            tank = evt.tank;
            
            tankState = SetKinematicStateTankState(tank);
            obj.tankStates(end+1) = tankState;  
            
            SetKinematicStateActionVariable(tankState); %doesn't need to get stored somewhere, it'll get stored on the tankState
        end
        
        function tankDeletedClbk(obj, src, evt)
            tank = evt.tank;
            
            obj.tankStates([obj.tankStates.tank] == tank) = [];
        end
        
        function epsSinkAddedClbk(obj, src, evt)
            sink = evt.sink;
            
            sinkState = SetKinematicStateEPSinkState(sink);
            obj.epsSinkStates(end+1) = sinkState;  
        end
        
        function epsSinkDeletedClbk(obj, src, evt)
            sink = evt.sink;
            
            obj.epsSinkStates([obj.epsSinkStates.sink] == sink) = [];
        end
        
        function epsSrcAddedClbk(obj, src, evt)
            src = evt.src;
            
            srcState = SetKinematicStateEPSrcState(src);
            obj.epsSrcStates(end+1) = srcState;  
        end
        
        function epsSrcDeletedClbk(obj, ~, evt)
            src = evt.src;
            
            obj.epsSrcStates([obj.epsSrcStates.src] == src) = [];
        end
        
        function epsStorageAddedClbk(obj, src, evt)
            storage = evt.storage;
            
            storageState = SetKinematicStateEPStorageState(storage);
            obj.epsStorageStates(end+1) = storageState; 
        end
        
        function epsStorageDeletedClbk(obj, src, evt)
            storage = evt.storage;
            
            obj.epsStorageStates([obj.epsStorageStates.storage] == storage) = [];
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            action.generateLvComponentElements();
            
            output = AppDesignerGUIOutput({false});
            lvd_EditActionSetKinematicStateGUI_App(action, lv.lvdData, output);
            
            addActionTf = output.output{1};
        end
    end
end