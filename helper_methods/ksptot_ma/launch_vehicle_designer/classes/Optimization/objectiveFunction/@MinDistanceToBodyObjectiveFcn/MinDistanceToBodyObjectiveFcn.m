classdef MinDistanceToBodyObjectiveFcn < AbstractObjectiveFcn
    %MinDistanceToBodyObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        event LaunchVehicleEvent
        targetBodyInfo KSPTOT_BodyInfo
        
        lvdOptim LvdOptimization
        lvdData LvdData
    end
    
    methods
        function obj = MinDistanceToBodyObjectiveFcn(event, targetBodyInfo, lvdOptim, lvdData)
            if(nargin > 0)
                obj.event = event;
                obj.targetBodyInfo = targetBodyInfo;
                obj.lvdOptim = lvdOptim;
                obj.lvdData = lvdData;
            end
        end
        
        function [f, stateLog] = evalObjFcn(obj, x, evtToStartScriptExecAt)
            obj.lvdOptim.vars.updateObjsWithScaledVarValues(x);
            stateLog = obj.lvdData.script.executeScript(true, evtToStartScriptExecAt, false, true);
            subStateLog = stateLog.getLastStateLogForEvent(obj.event);
            
            ut = subStateLog.time;
            rVect = subStateLog.position;
            bodyInfo = subStateLog.centralBody;
            
            dVect = getAbsPositBetweenSpacecraftAndBody(ut, rVect, bodyInfo, obj.targetBodyInfo, obj.lvdData.celBodyData);
            f = norm(dVect);
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
            tf = obj.event == event;
        end
        
        function event = getRefEvent(obj)
            event = obj.event;
        end
        
        function bodyInfo = getRefBody(obj)
            bodyInfo = obj.targetBodyInfo;
        end
    end

    methods(Static)
        function objFcn = getDefaultObjFcn(event, refBodyInfo, lvdOptim, lvdData)
            objFcn = MinDistanceToBodyObjectiveFcn(event, refBodyInfo, lvdOptim, lvdData);
        end
        
        function params = getParams()
            params = struct();
            
            params.usesEvents = true;
            params.usesBodies = true;
        end
    end
end