classdef(Abstract) AbstractConstraint < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        refStation struct
        refOtherSC struct
        refBodyInfo KSPTOT_BodyInfo
        
        active(1,1) logical = true
        
        id(1,1) double = 0;
    end
    
    methods
        [c, ceq, value, lb, ub, type, eventNum] = evalConstraint(obj, stateLog, celBodyData);
        
        [lb, ub] = getBounds(obj);
        
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
        
        function name = getName(obj)
            name = sprintf('%s - Event %i', obj.getConstraintType(), obj.getConstraintEvent().getEventNum());
        end
        
        function str = getListboxTooltipStr(obj)
            type = obj.getConstraintType();
            [lb, ub] = obj.getBounds();
            sF =obj.getScaleFactor();
            
            str = sprintf('%s\n\tBounds: [%0.3g, %0.3g]\n\tScale factor: %0.3g', ...
                          type, lb, ub, sF);
        end
        
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