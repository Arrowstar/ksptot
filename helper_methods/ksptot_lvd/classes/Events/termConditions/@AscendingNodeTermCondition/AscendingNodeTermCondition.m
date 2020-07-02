classdef AscendingNodeTermCondition < LatitudeTermCondition
    %AscendingNodeTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = AscendingNodeTermCondition()
            obj = obj@LatitudeTermCondition(0.0);
            obj.direction = 1.0;
        end
                
        function name = getName(obj)
            name = sprintf('Ascending Node');
        end
                
        function params = getTermCondUiStruct(obj)
            params = getTermCondUiStruct@LatitudeTermCondition(obj);  
            
            params.paramName = 'Ascending Node';
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
        
        function optVar = getNewOptVar(obj)
            optVar = AbstractOptimizationVariable.empty(0,1);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function termCond = getTermCondForParams(paramValue, stage, tank, engine, stopwatch)
            termCond = AscendingNodeTermCondition();
        end
    end
end