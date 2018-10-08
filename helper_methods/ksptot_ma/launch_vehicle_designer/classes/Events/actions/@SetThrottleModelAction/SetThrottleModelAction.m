classdef SetThrottleModelAction < AbstractEventAction
    %SetSteeringModelAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        throttleModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel()
    end
    
    methods
        function obj = SetThrottleModelAction(throttleModel)
            if(nargin > 0)
                obj.throttleModel = throttleModel;
            else
                obj.throttleModel = ThrottlePolyModel.getDefaultThrottleModel();
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = exectuteAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();
            newStateLogEntry.throttleModel = obj.throttleModel;
        end
        
        function initAction(obj, initialStateLogEntry)
            t0 = initialStateLogEntry.time;
            obj.throttleModel.setT0(t0);
        end
        
        function name = getName(obj)
            name = sprintf('Set Throttle Model');
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
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
            
            optVar = obj.throttleModel.getExistingOptVar();
            if(not(isempty(optVar)))
                tf = any(optVar.getUseTfForVariable());
                vars(end+1) = optVar;
            end
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_EditActionSetThrottleModelGUI(action, lv);
        end
    end
end