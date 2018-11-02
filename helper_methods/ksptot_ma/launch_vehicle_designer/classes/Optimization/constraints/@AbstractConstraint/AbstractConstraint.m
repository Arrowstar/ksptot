classdef(Abstract) AbstractConstraint < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [c, ceq, value, lb, ub, type, eventNum] = evalConstraint(obj, stateLog, celBodyData);
        
        sF = getScaleFactor(obj);
        
        setScaleFactor(obj, sF);
        
        tf = usesStage(obj, stage)
        
        tf = usesEngine(obj, engine)
        
        tf = usesTank(obj, tank)
        
        tf = usesEngineToTankConn(obj, engineToTank)
        
        tf = usesEvent(obj, event);
        
        name = getName(obj)
        
        addConstraintTf = openEditConstraintUI(obj, lvdData);
    end
    
    methods(Static)
        constraint = getDefaultConstraint(input1) 
    end
end