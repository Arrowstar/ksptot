classdef SetThrottleModelAction < AbstractEventAction
    %SetThrottleModelAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        throttleModels ThrottleModelsSet
    end

    %deprecated
    properties(Access=private)
        throttleModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel()
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = SetThrottleModelAction(throttleModel)
            obj.throttleModels = ThrottleModelsSet();

            if(nargin > 0)
                obj.throttleModels.selectedModel = throttleModel;
            else
                obj.throttleModels.selectedModel = ThrottlePolyModel.getDefaultThrottleModel();
            end
            
            obj.id = rand();
        end

%         function tm = get.throttleModel(obj)
%             tm = obj.throttleModel;
%             warning('Calling SetThrottleModelAction.throttleModel is deprecated.');
%         end
% 
%         function set.throttleModel(obj,tm)
%             obj.throttleModel = tm;
%             warning('Calling SetThrottleModelAction.throttleModel is deprecated.');
%         end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            newStateLogEntry.throttleModel = obj.throttleModels.selectedModel;
        end
        
        function initAction(obj, initialStateLogEntry)
            obj.throttleModels.selectedModel.initThrottleModel(initialStateLogEntry);
        end
        
        function name = getName(obj)
            name = sprintf('Set Throttle Model (%s)', obj.throttleModels.selectedModel.getThrottleModelTypeEnum().nameStr);
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
            
            optVar = obj.throttleModels.selectedModel.getExistingOptVar();
            if(not(isempty(optVar)))
                tf = any(optVar.getUseTfForVariable());
                vars(end+1) = optVar;
            end
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            arguments
                action SetThrottleModelAction
                lv LaunchVehicle
            end

            addActionTf = action.throttleModels.openEditDialog(lv.lvdData, true);
        end

        function obj = loadobj(obj)
            arguments
                obj SetThrottleModelAction
            end

            if(isempty(obj.throttleModels))
                obj.throttleModels = ThrottleModelsSet();
%                 obj.throttleModels.selectedModel = obj.throttleModel;

%             elseif(obj.throttleModels.selectedModel ~= obj.throttleModel)
%                 obj.throttleModels.selectedModel = obj.throttleModel;
            end
        end
    end
end