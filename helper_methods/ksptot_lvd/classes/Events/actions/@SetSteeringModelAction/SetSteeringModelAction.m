classdef SetSteeringModelAction < AbstractEventAction
    %SetSteeringModelAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        steeringModels SteeringModelsSet
    end

    %deprecated
    properties(Access=private)
        steeringModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel()
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = SetSteeringModelAction(steeringModel)
            obj.steeringModels = SteeringModelsSet();

            if(nargin > 0)
                obj.steeringModels.selectedModel = steeringModel;
            else
                obj.steeringModels.selectedModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            newStateLogEntry.steeringModel = obj.steeringModels.selectedModel;
        end
        
        function initAction(obj, initialStateLogEntry)
            t0 = initialStateLogEntry.time;
            obj.steeringModels.selectedModel.setT0(t0);
            
            dcm = initialStateLogEntry.attitude.dcm;
            rVect = initialStateLogEntry.position;
            vVect = initialStateLogEntry.velocity;
            bodyInfo = initialStateLogEntry.centralBody;
            obj.steeringModels.selectedModel.setConstsFromDcmAndContinuitySettings(dcm, t0, rVect, vVect, bodyInfo);
        end
        
        function name = getName(obj)
            name = sprintf('Set Steering Model (%s)', obj.steeringModels.selectedModel.getTypeNameStr());
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
            vars = obj.emptyVarArr;
            
            optVar = obj.steeringModels.selectedModel.getExistingOptVar();
            if(not(isempty(optVar)))
                tf = any(optVar.getUseTfForVariable());
                vars(end+1) = optVar;
            end
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            arguments
                action SetSteeringModelAction
                lv LaunchVehicle
            end
            
            addActionTf = action.steeringModels.openEditDialog(lv.lvdData, true);
        end

        function obj = loadobj(obj)
            arguments
                obj SetSteeringModelAction
            end

            if(isempty(obj.steeringModels))
                obj.steeringModels = SteeringModelsSet();
                obj.steeringModels.selectedModel = obj.steeringModel;

            elseif(obj.steeringModels.selectedModel ~= obj.steeringModel)
                obj.steeringModels.selectedModel = obj.steeringModel;
            end
        end
    end
end