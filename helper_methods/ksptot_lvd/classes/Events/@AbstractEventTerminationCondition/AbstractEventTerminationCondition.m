classdef(Abstract) AbstractEventTerminationCondition < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractEventTerminationCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        optVar
    end
    
    methods
        evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
        
        initTermCondition(obj, initialStateLogEntry)
        
        name = getName(obj)
        
        tf = shouldBeReinitOnRestart(obj);
        
        params = getTermCondUiStruct(obj)
        
        optVar = getNewOptVar(obj)
        
        optVar = getExistingOptVar(obj)
        
        tf = usesStage(obj, stage)
        
        tf = usesEngine(obj, engine)
        
        tf = usesTank(obj, tank)
        
        tf = usesEngineToTankConn(obj, engineToTank)
        
        tf = usesStopwatch(obj, stopwatch)
        
        function tf = usesPwrSink(obj, powerSink)
            tf = false;
        end
        
        function tf = usesPwrSrc(obj, powerSrc)
            tf = false;
        end
        
        function tf = usesPwrStorage(obj, powerStorage)
            tf = false;
        end
    end
    
    methods(Static)
        termCond = getTermCondForParams(paramValue, stage, tank, engine)
    end
end