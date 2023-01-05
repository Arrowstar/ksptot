classdef SoITransitionTermCondition < AbstractEventTerminationCondition
    %SoITransitionTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        celBodyData
    end
    
    methods
        function obj = SoITransitionTermCondition()

        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)            
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.bodyInfo = initialStateLogEntry.centralBody;
            obj.celBodyData = initialStateLogEntry.celBodyData;
        end
        
        function name = getName(obj)
            name = 'Next SoI Transition';
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = true;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Next SoI Transition';
            params.paramUnit = '';
            params.useParam = 'off';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            params.useStopwatches = 'off';
            
            params.value = [];
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
            params.refStopwatch = LaunchVehicleStopwatch.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = AbstractOptimizationVariable.empty(0,1);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = AbstractOptimizationVariable.empty(0,1);
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
    end
    
    methods(Static)
        function termCond = getTermCondForParams(paramValue, stage, tank, engine, stopwatch)
            termCond = SoITransitionTermCondition();
        end
    end
    
    methods(Access=private)
        function [value,isterminal,direction] = eventTermCond(obj, t,y)
            ut = t;
            rVect = y(1:3); 
            rVect = rVect(:);
            
            vVect = y(4:6);
            vVect = vVect(:);

            [soivalue, soiisterminal, soidirection, ~] = getSoITransitionOdeEvents(ut, rVect, vVect, obj.bodyInfo, obj.celBodyData);
            
            [value, I] = min(soivalue);
            isterminal = soiisterminal(I);
            direction = soidirection(I);
        end
    end
end