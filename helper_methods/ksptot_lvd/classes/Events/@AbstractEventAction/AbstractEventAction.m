classdef(Abstract) AbstractEventAction < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractEventAction Summary of this class goes here
    %   Detailed explanation goes here
        
    properties(Abstract=false)
        id(1,1) double
        event LaunchVehicleEvent
    end
    
    methods
        newStateLogEntry = executeAction(obj, stateLogEntry)
        
        initAction(obj, initialStateLogEntry)
        
        name = getName(obj)
        
        tf = usesStage(obj, stage)
        
        tf = usesEngine(obj, engine)
        
        tf = usesTank(obj, tank)
        
        tf = usesEngineToTankConn(obj, engineToTank)
        
        tf = usesStopwatch(obj, stopwatch)
        
        tf = usesExtremum(obj, extremum)
        
        tf = usesTankToTankConn(obj, tankToTank)
        
        function tf = usesCalculusCalc(obj, calculusCalc)
            tf = false;
        end
        
        function tf = usesEvent(obj, event)
            tf = false;
        end
        
        function tf = usesPwrSink(obj, powerSink)
            tf = false;
        end
        
        function tf = usesPwrSrc(obj, powerSrc)
            tf = false;
        end
        
        function tf = usesPwrStorage(obj, powerStorage)
            tf = false;
        end
        
        function tf = usesSensor(obj, sensor)
            tf = false;
        end
        
        [tf,vars] = hasActiveOptimVar(obj)
    end
    
    methods(Sealed)
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
        end  
    end
    
    methods(Static)
        addActionTf = openEditActionUI(action, lv);
    end
end