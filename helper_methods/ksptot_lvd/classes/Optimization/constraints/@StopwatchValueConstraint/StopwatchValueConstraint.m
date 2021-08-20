classdef StopwatchValueConstraint < AbstractConstraint
    %StopwatchValueConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        normFact = 1;
        event LaunchVehicleEvent
        eventNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
        stopwatch LaunchVehicleStopwatch
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        evalType(1,1) ConstraintEvalTypeEnum = ConstraintEvalTypeEnum.FixedBounds;
        stateCompType(1,1) ConstraintStateComparisonTypeEnum = ConstraintStateComparisonTypeEnum.Equals;
        stateCompEvent LaunchVehicleEvent
        stateCompNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
    end
    
    methods
        function obj = StopwatchValueConstraint(event, lb, ub)
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
            
            stopWatchStates = stateLogEntry.getAllStopwatchStates();
            stopWatchState = stopWatchStates(stopWatchStates.stopwatch == obj.stopwatch);
            
            value = stopWatchState.value;
                       
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                switch obj.stateCompNode
                    case ConstraintStateComparisonNodeEnum.FinalState
                        stateLogEntryStateComp = stateLog.getLastStateLogForEvent(obj.stateCompEvent);

                    case ConstraintStateComparisonNodeEnum.InitialState
                        stateLogEntryStateComp = stateLog.getFirstStateLogForEvent(obj.stateCompEvent);

                    otherwise
                        error('Unknown event node.');
                end

                stopWatchStates = stateLogEntryStateComp.getAllStopwatchStates();
                stopWatchState = stopWatchStates(stopWatchStates.stopwatch == obj.stopwatch);

                valueStateComp = stopWatchState.value;
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
            tf = obj.stopwatch == stopwatch;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = canUseSparseOutput(obj)
            tf = true;
        end
        
        function event = getConstraintEvent(obj)
            event = obj.event;
        end
        
        function type = getConstraintType(obj)
            type = 'Stopwatch Value';
        end
        
%         function name = getName(obj)
%             name = sprintf('%s - Event %i', obj.getConstraintType(), obj.event.getEventNum());
%         end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = 'sec';
            lbLim = -Inf;
            ubLim = Inf;
            usesLbUb = true;
            usesCelBody = false;
            usesRefSc = false;
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
%             [listBoxStr, stopwatches] = lvdData.launchVehicle.getStopwatchesListBoxStr();
% 
%             if(isempty(stopwatches))
%                 addConstraintTf = false;
%                 
%                 warndlg('Cannot create stopwatch value constraint: no stopwatches have been created.  Create a stopwatch first.','Stopwatch Value Constraint','modal');
%             else
%                 [Selection,ok] = listdlg('PromptString',{'Select the stopwatch','to constraint:'},...
%                                 'SelectionMode','single',...
%                                 'Name','Stopwatch',...
%                                 'ListString',listBoxStr);
%                             
%                 if(ok == 0)
%                     addConstraintTf = false;
%                 else
%                     sw = stopwatches(Selection);
%                     obj.stopwatch = sw;
%                     
%                     addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
%                 end
%             end

            sw = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(sw)))
                obj.stopwatch = sw;
                addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
            else
                addConstraintTf = false;
            end
        end
        
        function sw = selectConstraintObj(obj, lvdData)
            [listBoxStr, stopwatches] = lvdData.launchVehicle.getStopwatchesListBoxStr();

            if(isempty(stopwatches))                
                warndlg('Cannot create stopwatch value object: no stopwatches have been created.  Create a stopwatch first.','Stopwatch Value Constraint','modal');
            else
                [Selection,ok] = listdlg('PromptString',{'Select the stopwatch:'},...
                                'SelectionMode','single',...
                                'Name','Stopwatch',...
                                'ListString',listBoxStr);
                            
                if(ok == 0)
                    sw = [];
                else
                    sw = stopwatches(Selection);
                end
            end
        end
        
        function useObjFcn = setupForUseAsObjectiveFcn(obj,lvdData)
            sw = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(sw)))
                obj.stopwatch = sw;
                useObjFcn = true;
            else
                useObjFcn = false;
            end
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = StopwatchValueConstraint(LaunchVehicleEvent.empty(1,0),0,0);
        end
    end
end