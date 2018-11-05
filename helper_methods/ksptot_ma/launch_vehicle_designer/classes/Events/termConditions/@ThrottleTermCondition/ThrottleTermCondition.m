classdef ThrottleTermCondition < AbstractEventTerminationCondition
    %ThrottleTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        throttleModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();
        targetThrottle(1,1) double = 0;
    end
    
    methods
        function obj = ThrottleTermCondition(targetThrottle)
            obj.targetThrottle = targetThrottle;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, obj.targetThrottle, obj.throttleModel);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.throttleModel = initialStateLogEntry.throttleModel;
        end
        
        function name = getName(obj)
            name = sprintf('Throttle Setting (%.3f %%)', 100*obj.targetThrottle);
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = false;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Target Throttle Setting';
            params.paramUnit = '%';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            
            params.value = 100*obj.targetThrottle;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = ThrottleTermCondOptimVar(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
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
    end
    
    methods(Static)
        function termCond = getTermCondForParams(paramValue, stage, tank, engine)
            termCond = ThrottleTermCondition(paramValue);
        end
    end
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(t,y, targetThrottle, throttleModel)
            ut = t;
            
            throttle = throttleModel.getThrottleAtTime(ut);
            
            value = throttle - targetThrottle;
            isterminal = 1;
            direction = 0;
        end
    end
end