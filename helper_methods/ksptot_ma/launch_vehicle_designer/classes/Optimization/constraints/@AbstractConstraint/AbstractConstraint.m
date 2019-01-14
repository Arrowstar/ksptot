classdef(Abstract) AbstractConstraint < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        refStation(1,:) struct
        refOtherSC(1,:) struct
        refBodyInfo(1,:) KSPTOT_BodyInfo
        
        id(1,1) double = 0;
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
        
        tf = usesStopwatch(obj, stopwatch);
        
        tf = usesExtremum(obj, extremum);
        
        tf = canUseSparseOutput(obj);
        
        event = getConstraintEvent(obj);
        
        type = getConstraintType(obj);
        
        name = getName(obj)
        
        [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
        
        addConstraintTf = openEditConstraintUI(obj, lvdData);
    end
    
    methods(Static)
        constraint = getDefaultConstraint(input1) 
        
        function s = loadobj(s)
            if(s.id == 0)
                s.id = rand();
            end
        end
    end
    
    methods(Sealed)        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
        end 
        
        function tf = ne(A,B)
            tf = [A.id] ~= [B.id];
        end 
    end
end