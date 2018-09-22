classdef(Abstract) AbstractConstraint < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [c, ceq, value, lb, ub, type, eventNum] = evalConstraint(obj, stateLog, maData);
        
        tf = usesStage(obj, stage)
        
        tf = usesEngine(obj, engine)
        
        tf = usesTank(obj, tank)
        
        tf = usesEngineToTankConn(obj, engineToTank)
        
        name = getName(obj)
        
        addConstraintTf = openEditConstraintUI(obj, maData, lvdData, hMaMainGUI);
    end
    
    methods(Static)
        constraint = getDefaultConstraint(input1) 
    end
end