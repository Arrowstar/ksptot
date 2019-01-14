classdef(Abstract) AbstractEventAction < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractEventAction Summary of this class goes here
    %   Detailed explanation goes here
        
    properties(Abstract=false)
        id(1,1) double
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