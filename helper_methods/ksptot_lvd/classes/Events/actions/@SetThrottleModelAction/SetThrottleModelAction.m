classdef SetThrottleModelAction < AbstractEventAction
    %SetSteeringModelAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        throttleModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel()
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = SetThrottleModelAction(throttleModel)
            if(nargin > 0)
                obj.throttleModel = throttleModel;
            else
                [throttleModelNameStrs, enums] = ThrottleModelEnum.getThrottleModelTypeNameStrs();
                [dialogInd,tf] = listdlg('ListString',throttleModelNameStrs, ...
                                         'Name','Select Throttle Model', ...
                                         'PromptString',{'Select throttle model type:'}, ...
                                         'SelectionMode','single', ...
                                         'ListSize',[300 300]);
                if(tf)
                    m = enums(dialogInd);
                    obj.throttleModel = eval(sprintf('%s.%s',m.classNameStr,'getDefaultThrottleModel()'));
                else
                    obj.throttleModel = ThrottlePolyModel.getDefaultThrottleModel();
                end
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            newStateLogEntry.throttleModel = obj.throttleModel;
        end
        
        function initAction(obj, initialStateLogEntry)
            obj.throttleModel.initThrottleModel(initialStateLogEntry);
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
            
            optVar = obj.throttleModel.getExistingOptVar();
            if(not(isempty(optVar)))
                tf = any(optVar.getUseTfForVariable());
                vars(end+1) = optVar;
            end
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            switch class(action.throttleModel)
                case ThrottleModelEnum.PolyModel.classNameStr
                    addActionTf = lvd_EditActionSetThrottleModelGUI(action, lv);
                case ThrottleModelEnum.T2WModel.classNameStr
                    addActionTf = lvd_EditT2WThrottleModelGUI(action, lv);
                otherwise
                    error('Unknown throttle model class type: %s', class(action.throttleModel));
            end
        end
    end
end