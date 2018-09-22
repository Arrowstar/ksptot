classdef NoOptimizationObjectiveFcn < AbstractObjectiveFcn
    %NoOptimizationObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = NoOptimizationObjectiveFcn()
            
        end
        
        function [f, stateLog] = evalObjFcn(obj, x, ~)
            obj.lvdOptim.vars.updateObjsWithVarValues(x);
            stateLog = obj.lvdData.script.executeScript();
            
            f = 1;
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
        
        function event = getRefEvent(obj)
            event = LaunchVehicleEvent.empty(1,0);
        end
    end

    methods(Static)
        function objFcn = getDefaultObjFcn(event, lvdOptim, lvdData)
            objFcn = NoOptimizationObjectiveFcn();
        end
        
        function params = getParams()
            params = struct();
            
            params.usesEvents = false;
        end
    end
end