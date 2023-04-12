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

        function tf = usesPlugin(obj, plugin)
            arguments
                obj(1,1) AbstractEventAction
                plugin(1,1) LvdPlugin
            end

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