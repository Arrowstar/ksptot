classdef(Abstract) AbstractConstraint < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        refStation struct
        refOtherSC struct
        frame AbstractReferenceFrame
        
        active(1,1) logical = true
        
        id(1,1) double = 0;
        
        %deprecated
        refBodyInfo KSPTOT_BodyInfo
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
        
        function tf = usesPlugin(~, ~)
            tf = false;
        end 
        
        function tf = canUseSparseOutput(obj)
            tf = true;
        end
        
        event = getConstraintEvent(obj);
        
        type = getConstraintType(obj);
        
        function name = getName(obj)
            name = sprintf('%s - Event %i', obj.getConstraintType(), obj.getConstraintEvent().getEventNum());
        end
        
        function str = getListboxTooltipStr(obj, scaledValue)
            type = obj.getConstraintType();
            [lb, ub] = obj.getBounds();
            sF = obj.getScaleFactor();
            eventNum = obj.event.getEventNum();
            evtNodeStr = obj.eventNode.name;
            stateCompNodeStr = obj.stateCompNode.name;
            
            if(not(isempty(obj.frame)))
                frameStr = sprintf('\n\tFrame: %s', obj.frame.getNameStr());
            else
                frameStr = '';
            end
            
            if(obj.evalType == ConstraintEvalTypeEnum.FixedBounds)
                str = sprintf('%s\n\tEvent %u %s \n\tBounds: [%0.3g, %0.3g]\n\tScale factor: %0.3g%s\n\tScaled Value (last run): %0.8f', ...
                              type, eventNum, evtNodeStr, lb, ub, sF, frameStr, scaledValue);
                          
            elseif(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                symbol = obj.stateCompType.symbol;
                compEventNum = obj.stateCompEvent.getEventNum();
                
                str = sprintf('%s\n\tEvent %u %s %s %s Event %u %s %s\n\tScale factor: %0.3g%s\n\tScaled Value (last run): %0.8f', ...
                              type, eventNum, evtNodeStr, type, symbol, compEventNum, stateCompNodeStr, type, sF, frameStr, scaledValue);
                
            else
                error('Unknown constraint evaluation type.');
            end
        end
        
        [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
        
        addConstraintTf = openEditConstraintUI(obj, lvdData);
        
        function useObjFcn = setupForUseAsObjectiveFcn(~,~)
            useObjFcn = true;
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
        
        function obj = loadobj(obj)
            if(obj.id == 0)
                obj.id = rand();
            end

            if(isempty(obj.frame))
                if(not(isempty(obj.refBodyInfo)))
                    obj.frame = obj.refBodyInfo.getBodyCenteredInertialFrame();
                end
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