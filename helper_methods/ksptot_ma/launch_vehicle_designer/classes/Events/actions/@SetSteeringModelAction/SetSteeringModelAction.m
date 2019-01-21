classdef SetSteeringModelAction < AbstractEventAction
    %SetSteeringModelAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        steeringModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel()
    end
    
    methods
        function obj = SetSteeringModelAction(steeringModel)
            if(nargin > 0)
                obj.steeringModel = steeringModel;
            else
                obj.steeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            newStateLogEntry.steeringModel = obj.steeringModel;
        end
        
        function initAction(obj, initialStateLogEntry)
            t0 = initialStateLogEntry.time;
            obj.steeringModel.setT0(t0);
            
            dcm = initialStateLogEntry.attitude.dcm;
            rVect = initialStateLogEntry.position;
            vVect = initialStateLogEntry.velocity;
            bodyInfo = initialStateLogEntry.centralBody;
            obj.steeringModel.setConstsFromDcmAndContinuitySettings(dcm, t0, rVect, vVect, bodyInfo);
        end
        
        function name = getName(obj)
            name = sprintf('Set Steering Model (%s)', obj.steeringModel.getTypeNameStr());
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
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
            
            optVar = obj.steeringModel.getExistingOptVar();
            if(not(isempty(optVar)))
                tf = any(optVar.getUseTfForVariable());
                vars(end+1) = optVar;
            end
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_EditActionSetSteeringModelGUI(action, lv);
        end
    end
end