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
        [c, ceq, value, lb, ub, type, eventNum, valueStateComp] = evalConstraint(obj, stateLog, celBodyData);
        
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
        
        function tf = usesGroundObj(~, ~)
            tf = false;
        end
        
        function tf = usesCalculusCalc(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricPoint(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricVector(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricCoordSys(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricRefFrame(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricAngle(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricPlane(~, ~)
            tf = false;
        end 
        
        tf = canUseSparseOutput(obj);
        
        event = getConstraintEvent(obj);
        
        type = getConstraintType(obj);
        
        function name = getName(obj)
            name = sprintf('%s - Event %i', obj.getConstraintType(), obj.getConstraintEvent().getEventNum());
        end
        
        function str = getListboxTooltipStr(obj)
            type = obj.getConstraintType();
            [lb, ub] = obj.getBounds();
            sF = obj.getScaleFactor();
            
            if(obj.evalType == ConstraintEvalTypeEnum.FixedBounds)
                str = sprintf('%s\n\tBounds: [%0.3g, %0.3g]\n\tScale factor: %0.3g', ...
                              type, lb, ub, sF);
                          
            elseif(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                symbol = obj.stateCompType.symbol;
                compEvent = obj.stateCompEvent;
                compEventNum = compEvent.getEventNum();
                
                str = sprintf('%s\n\t%s Event %u %s\n\tScale factor: %0.3g', ...
                              type, symbol, compEventNum, type, sF);
                
            else
                error('Unknown constraint evaluation type.');
            end
        end
        
        [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
        
        addConstraintTf = openEditConstraintUI(obj, lvdData);
        
        function setupForUseAsObjectiveFcn(~,~)
            return; %nothing
        end
    end
    
    methods(Access=protected)
        function [c, ceq] = computeCAndCeqValues(obj, value, valueStateComp)
            if(obj.evalType == ConstraintEvalTypeEnum.FixedBounds)
                if(obj.lb == obj.ub)
                    c = [];
                    ceq(1) = value - obj.ub;
                else
                    c(1) = obj.lb - value;
                    c(2) = value - obj.ub;
                    ceq = [];
                end
                
            elseif(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                switch obj.stateCompType
                    case ConstraintStateComparisonTypeEnum.Equals
                        c = [];
                        ceq = value - valueStateComp;
                        
                    case ConstraintStateComparisonTypeEnum.GreaterThan
                        c = valueStateComp - value;
                        ceq = [];
                        
                    case ConstraintStateComparisonTypeEnum.LessThan
                        c = value - valueStateComp;
                        ceq = [];
                        
                    otherwise
                        error('Unknown constraint state comparison type.');
                end
                
            else
                error('Unknown constraint evaluation type.');
            end
            
            c = c/obj.normFact;
            ceq = ceq/obj.normFact; 
        end
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