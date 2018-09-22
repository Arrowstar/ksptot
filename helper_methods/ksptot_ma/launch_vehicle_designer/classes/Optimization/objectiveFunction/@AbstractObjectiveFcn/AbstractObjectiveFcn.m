classdef(Abstract) AbstractObjectiveFcn < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [f, stateLog] = evalObjFcn(obj, x, maData);
        
        tf = usesStage(obj, stage)
        
        tf = usesEngine(obj, engine)
        
        tf = usesTank(obj, tank)
        
        tf = usesEngineToTankConn(obj, engineToTank)
    end
end