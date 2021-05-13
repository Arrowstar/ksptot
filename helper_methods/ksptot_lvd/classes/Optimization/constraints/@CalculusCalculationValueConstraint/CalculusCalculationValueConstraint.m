classdef CalculusCalculationValueConstraint < AbstractConstraint
    %CalculusCalculationValueConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        normFact = 1;
        event LaunchVehicleEvent
        eventNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
        calculusCalc AbstractLaunchVehicleCalculusCalc
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        evalType(1,1) ConstraintEvalTypeEnum = ConstraintEvalTypeEnum.FixedBounds;
        stateCompType(1,1) ConstraintStateComparisonTypeEnum = ConstraintStateComparisonTypeEnum.Equals;
        stateCompEvent LaunchVehicleEvent
        stateCompNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
    end
    
    methods
        function obj = CalculusCalculationValueConstraint(event, lb, ub)
            obj.event = event;
            obj.lb = lb;
            obj.ub = ub;   
            
            obj.id = rand();
        end
        
        function [lb, ub] = getBounds(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function [c, ceq, value, lwrBnd, uprBnd, type, eventNum, valueStateComp] = evalConstraint(obj, stateLog, celBodyData)           
            type = obj.getConstraintType();
            
            switch obj.eventNode
                case ConstraintStateComparisonNodeEnum.FinalState
                    stateLogEntry = stateLog.getLastStateLogForEvent(obj.event);
                    
                case ConstraintStateComparisonNodeEnum.InitialState
                    stateLogEntry = stateLog.getFirstStateLogForEvent(obj.event);
                
                otherwise
                    error('Unknown event node.');
            end
            
            cObjStates = stateLogEntry.getAllCalculusObjStates();
            cObjState = cObjStates([cObjStates.calcObj] == obj.calculusCalc);
            
            time = stateLogEntry.time;
            value = cObjState.getValueAtTime(time);
                       
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                switch obj.stateCompNode
                    case ConstraintStateComparisonNodeEnum.FinalState
                        stateLogEntryStateComp = stateLog.getLastStateLogForEvent(obj.stateCompEvent);

                    case ConstraintStateComparisonNodeEnum.InitialState
                        stateLogEntryStateComp = stateLog.getFirstStateLogForEvent(obj.stateCompEvent);

                    otherwise
                        error('Unknown event node.');
                end
                
                time = stateLogEntryStateComp.time;
                valueStateComp = cObjState.getValueAtTime(time);
            else
                valueStateComp = NaN;
            end
            
            [c, ceq] = obj.computeCAndCeqValues(value, valueStateComp); 
            
            lwrBnd = obj.lb;
            uprBnd = obj.ub;
            
            eventNum = obj.event.getEventNum();
        end
        
        function sF = getScaleFactor(obj)
            sF = obj.normFact;
        end
        
        function setScaleFactor(obj, sF)
            obj.normFact = sF;
        end
        
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
        
        function tf = usesEvent(obj, event)
            tf = obj.event == event;
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                tf = tf || obj.stateCompEvent == event;
            end
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = usesCalculusCalc(obj, calculusCalc)
            tf = [obj.calculusCalc] == calculusCalc;
        end
        
        function tf = canUseSparseOutput(obj)
            tf = false;
        end
        
        function event = getConstraintEvent(obj)
            event = obj.event;
        end
        
        function type = getConstraintType(obj)
            type = 'Calculus Calculation Value';
        end
                
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = obj.calculusCalc.unitStr;
            lbLim = -Inf;
            ubLim = Inf;
            usesLbUb = true;
            usesCelBody = false;
            usesRefSc = false;
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
%             [listBoxStr, calcObjs] = lvdData.launchVehicle.getCalculusCalcObjListBoxStr();
% 
%             if(isempty(calcObjs))
%                 addConstraintTf = false;
%                 
%                 warndlg('Cannot create calculus calculation constraint: no calculus calculations have been created.  Create a calculus calculation first.','Calculus Calculation Constraint','modal');
%             else
%                 [Selection,ok] = listdlg('PromptString',{'Select the calculus calculation','to constrain:'},...
%                                 'SelectionMode','single',...
%                                 'Name','Calculus Calculation',...
%                                 'ListString',listBoxStr);
%                             
%                 if(ok == 0)
%                     addConstraintTf = false;
%                 else
%                     calcObj = calcObjs(Selection);
%                     obj.calculusCalc = calcObj;
%                     
%                     addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
%                 end
%             end
            calcObj = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(calcObj)))
                obj.calculusCalc = calcObj;
                addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
            else
                addConstraintTf = false;
            end
        end
        
        function [calcObj] = selectConstraintObj(obj, lvdData)
            [listBoxStr, calcObjs] = lvdData.launchVehicle.getCalculusCalcObjListBoxStr();

            calcObj = [];
            if(isempty(calcObjs))                
                warndlg('Cannot create calculus calculation-based object: no calculus calculations have been created.  Create a calculus calculation first.','Calculus Calculation Constraint','modal');
            else
                [Selection,ok] = listdlg('PromptString',{'Select a calculus calculation:'},...
                                'SelectionMode','single',...
                                'Name','Calculus Calculation',...
                                'ListString',listBoxStr);
                            
                if(ok == 0)
                    calcObj = [];
                else
                    calcObj = calcObjs(Selection);
                end
            end
        end
        
        function setupForUseAsObjectiveFcn(obj,lvdData)
            calcObj = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(calcObj)))
                obj.calculusCalc = calcObj;
            end
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, lvdData)     
            evt = lvdData.script.getEventForInd(1);
            constraint = CalculusCalculationValueConstraint(evt,0,0);
            
%             addConstraintTf = constraint.openEditConstraintUI(lvdData);
%             
%             if(addConstraintTf == false)
%                 constraint = CalculusCalculationValueConstraint.empty(1,0);
%             end
        end
    end
end