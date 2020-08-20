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
        inheritStageStates(1,1) logical = true;
        inheritStageStatesFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritStageStatesFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0);
        
        %Inherit all other state elements
        inheritStateElems(1,1) logical = true;
        inheritStateElemsFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritStateElemsFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0);
        
        optVar SetKinematicStateActionVariable
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
            newStateLogEntry = stateLogEntry;

            if(obj.inheritTime)
                if(obj.inheritTimeFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritTimeFromEvent)) && ...
                   not(isempty(obj.inheritTimeFromEvent.getEventNum())) && ...
                   obj.inheritTimeFromEvent.getEventNum() > 0)
               
                    timeEvtStateLog = obj.stateLog.getLastStateLogForEvent(obj.inheritTimeFromEvent);
                    if(not(isempty(timeEvtStateLog)))
                        newStateLogEntry.time = timeEvtStateLog(end).time;
                    end
                end
            else
                newStateLogEntry.time = obj.orbitModel.time;
            end
            
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
                rVect = cartElemSet.rVect;
                vVect = cartElemSet.vVect;
                bodyInfo = cartElemSet.frame.getOriginBody();
                
                newStateLogEntry.position = rVect;
                newStateLogEntry.velocity = vVect;
                newStateLogEntry.centralBody = bodyInfo;
            end
            
            if(obj.inheritStageStates)
                if(obj.inheritStageStatesFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritStageStatesFromEvent)) && ...
                   not(isempty(obj.inheritStageStatesFromEvent.getEventNum())) && ...
                   obj.inheritStageStatesFromEvent.getEventNum() > 0)
               
               
                    stageStateEvtState = obj.stateLog.getLastStateLogForEvent(obj.inheritStageStatesFromEvent);
                    stageStateEvtState = stageStateEvtState(end);
                    if(not(isempty(stageStateEvtState)))
                        lvState = stageStateEvtState.lvState.deepCopy();
                        newStateLogEntry.lvState = lvState;
                        
                        for(i=1:length(stageStateEvtState.stageStates)) %#ok<NO4LP>
                            newStateLogEntry.stageStates(i) = stageStateEvtState.stageStates(i).deepCopy(true, lvState);
                        end
                    end
                end
                
            else
                %do nothing, there is no behavior for this yet
                warning('SetKinematicStateAction.inheritStageStates must be set to true, no behavior yet defined when this is set to false.');
            end
            
            if(obj.inheritStateElems)
              if(obj.inheritStateElemsFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritStateElemsFromEvent)) && ...
                   not(isempty(obj.inheritStateElemsFromEvent.getEventNum())) && ...
                   obj.inheritStateElemsFromEvent.getEventNum() > 0)
               
                    stateElemsEvtState = obj.stateLog.getLastStateLogForEvent(obj.inheritStateElemsFromEvent);
                    stateElemsEvtState = stateElemsEvtState(end);
                    
                    if(not(isempty(stateElemsEvtState)))
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
            
            if((obj.inheritTime && obj.inheritTimeFrom == InheritStateEnum.InheritFromSpecifiedEvent && not(isempty(obj.inheritTimeFromEvent)) && obj.inheritTimeFromEvent == event) || ...
               (obj.inheritPosVel && obj.inheritPosVelFrom == InheritStateEnum.InheritFromSpecifiedEvent && not(isempty(obj.inheritPosVelFromEvent)) && obj.inheritPosVelFromEvent == event) || ...
               (obj.inheritStageStates && obj.inheritStageStatesFrom == InheritStateEnum.InheritFromSpecifiedEvent && not(isempty(obj.inheritStageStatesFromEvent)) && obj.inheritStageStatesFromEvent == event))
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
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_EditActionSetKinematicStateGUI(action, lv.lvdData);
        end
    end
end