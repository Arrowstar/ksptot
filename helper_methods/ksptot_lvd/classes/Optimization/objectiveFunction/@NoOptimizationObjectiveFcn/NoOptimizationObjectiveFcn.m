classdef NoOptimizationObjectiveFcn < AbstractObjectiveFcn
    %NoOptimizationObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdOptim LvdOptimization
        lvdData LvdData
    end
    
    methods
        function obj = NoOptimizationObjectiveFcn(lvdOptim, lvdData)
            if(nargin > 0)
                obj.lvdOptim = lvdOptim;
                obj.lvdData = lvdData;
            end
        end
        
        function [f, stateLog] = evalObjFcn(obj, x, evtToStartScriptExecAt)
            obj.lvdOptim.vars.updateObjsWithScaledVarValues(x);
            stateLog = obj.lvdData.script.executeScript(true, evtToStartScriptExecAt, false, true, false);
            
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
        
        function tf = usesEvent(obj, event)
            tf = false;
        end
        
        function event = getRefEvent(obj)
            event = LaunchVehicleEvent.empty(1,0);
        end

        function bodyInfo = getRefBody(obj)
            bodyInfo = KSPTOT_BodyInfo.empty(0,1);
        end
    end

    methods(Static)
        function objFcn = getDefaultObjFcn(event, refBodyInfo, lvdOptim, lvdData)
            objFcn = NoOptimizationObjectiveFcn(lvdOptim, lvdData);
        end
        
        function params = getParams()
            params = struct();
            
            params.usesEvents = false;
            params.usesBodies = false;
        end
    end
end