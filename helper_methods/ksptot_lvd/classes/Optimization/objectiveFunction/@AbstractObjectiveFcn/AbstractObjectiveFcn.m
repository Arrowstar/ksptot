classdef(Abstract) AbstractObjectiveFcn < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [f, stateLog] = evalObjFcn(obj, x, evtToStartScriptExecAt);
        
        tf = usesStage(obj, stage)
        
        tf = usesEngine(obj, engine)
        
        tf = usesTank(obj, tank)
        
        tf = usesEngineToTankConn(obj, engineToTank)
        
        tf = usesEvent(obj, event)
        
        event = getRefEvent(obj)     
        
        bodyInfo = getRefBody(obj)
    end
    
    methods(Static)
        objFcn = getDefaultObjFcn(event, refBodyInfo, lvdOptim, lvdData)
        
        params = getParams(obj)
    end
end