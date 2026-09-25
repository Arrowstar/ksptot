classdef GenericMAConstraint < AbstractConstraint
    %GenericMAConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        constraintType char = '';
        normFact = 1;
        event LaunchVehicleEvent
        eventNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        evalType(1,1) ConstraintEvalTypeEnum = ConstraintEvalTypeEnum.FixedBounds;
        stateCompType(1,1) ConstraintStateComparisonTypeEnum = ConstraintStateComparisonTypeEnum.Equals;
        stateCompEvent LaunchVehicleEvent
        stateCompNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
    end
    
    methods
        function obj = GenericMAConstraint(constraintType, event, lb, ub, refStation, refOtherSC, refBodyInfo)
            obj.constraintType = constraintType;
            obj.event = event;
            obj.lb = lb;
            obj.ub = ub;
            obj.refStation = refStation;
            obj.refOtherSC = refOtherSC;
            obj.refBodyInfo = refBodyInfo; 
            
            obj.id = rand();
        end
        
        function [lb, ub] = getBounds(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function [c, ceq, value, lwrBnd, uprBnd, type, eventNum, valueStateComp] = evalConstraint(obj, stateLog, celBodyData)   
            maTaskList = ma_getGraphAnalysisTaskList(getLvdGAExcludeList());
            type = obj.constraintType;
            
            switch obj.eventNode
                case ConstraintStateComparisonNodeEnum.FinalState
                    stateLogEntry = stateLog.getLastStateLogForEvent(obj.event);
                    
                case ConstraintStateComparisonNodeEnum.InitialState
                    stateLogEntry = stateLog.getFirstStateLogForEvent(obj.event);
                
                otherwise
                    error('Unknown event node.');
            end
                       
            if(not(isempty(obj.frame)))
                frame = obj.frame;
            else
                frame = stateLogEntry.centralBody.getBodyCenteredInertialFrame();
            end
            
            if(not(isempty(obj.refBodyInfo)))
                refBodyId = obj.refBodyInfo.id;
            else
                refBodyId = [];
            end
                                    
            if(strcmp(obj.constraintType, 'Cumulative Delta-V Expended'))
                %History-dependent: integrate over the full log up to the
                %constrained node rather than evaluating the lone entry.
                value = GenericMAConstraint.getCumulativeDeltaVUpToNode(stateLog, obj.event, obj.eventNode);
            else
                value = obj.getValueForConstraint(stateLogEntry, type, maTaskList, refBodyId, celBodyData, frame);
            end
                    
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                switch obj.stateCompNode
                    case ConstraintStateComparisonNodeEnum.FinalState
                        stateLogEntryStateComp = stateLog.getLastStateLogForEvent(obj.stateCompEvent).deepCopy();

                    case ConstraintStateComparisonNodeEnum.InitialState
                        stateLogEntryStateComp = stateLog.getFirstStateLogForEvent(obj.stateCompEvent).deepCopy();

                    otherwise
                        error('Unknown event node.');
                end
                
                cartElem = stateLogEntryStateComp.getCartesianElementSetRepresentation().convertToFrame(frame);
                stateLogEntryStateComp.setCartesianElementSet(cartElem);

                if(strcmp(obj.constraintType, 'Cumulative Delta-V Expended'))
                    valueStateComp = GenericMAConstraint.getCumulativeDeltaVUpToNode(stateLog, obj.stateCompEvent, obj.stateCompNode);
                else
                    valueStateComp = obj.getValueForConstraint(stateLogEntryStateComp, type, maTaskList, refBodyId, celBodyData, frame);
                end
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
        
        function tf = canUseSparseOutput(obj)
            tf = true;
        end
        
        function event = getConstraintEvent(obj)
            event = obj.event;
        end
        
        function type = getConstraintType(obj)
            type = obj.constraintType;
        end
                
%         function name = getName(obj)
%             name = sprintf('%s - Event %i', obj.getConstraintType(), obj.event.getEventNum());
%         end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            [unit, lbLim, ubLim, ~, ~, ~, ~, usesLbUb, usesCelBody, usesRefSc] = ma_getConstraintStaticDetails(obj.constraintType);           
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
%             addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
            
            output = AppDesignerGUIOutput({false});
            lvd_EditGenericMAConstraintGUI_App(obj, lvdData, output);
            addConstraintTf = output.output{1}; 
        end
        
        function value = getValueForConstraint(obj, stateLogEntry, type, maTaskList, refBodyId, celBodyData, frame)
            if(ismember(type,maTaskList))
                oscId = -1;
                if(not(isempty(obj.refOtherSC)))
                    oscId = obj.refOtherSC.id;
                end

                stnId = -1;
                if(not(isempty(obj.refStation)))
                    stnId = obj.refStation.id;
                end
                
                maData.spacecraft = struct();
                propNames = obj.event.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
                
                stateLogEntryMA = stateLogEntry.getMAFormattedStateLogMatrix(true);
                value = ma_getDepVarValueUnit(1, stateLogEntryMA, type, 0, refBodyId, oscId, stnId, propNames, maData, celBodyData, false);
                
            else
                try
                    [value, ~] = lvd_getDepVarValueUnit(1, stateLogEntry, type, refBodyId, celBodyData, false, frame);
                catch ME
                    warning('Could not evaluate constraint of type: %s', obj.constraintType);
                    value = 0;
                end
            end
        end
    end
    
    methods(Static)
        function value = getCumulativeDeltaVUpToNode(stateLog, event, node)
            %getCumulativeDeltaVUpToNode Cumulative Delta-V expended from
            %script start through the given event node, integrated over the
            %full state log (the lone node entry carries no history).
            entries = stateLog.getAllEntries();
            subEntries = entries([entries.event] == event);
            
            if(isempty(subEntries))
                value = NaN;
                return;
            end
            
            switch node
                case ConstraintStateComparisonNodeEnum.FinalState
                    targetEntry = subEntries(end);
                case ConstraintStateComparisonNodeEnum.InitialState
                    targetEntry = subEntries(1);
                otherwise
                    error('Unknown event node.');
            end
            
            ind = find(entries == targetEntry, 1, 'first');
            if(isempty(ind))
                value = NaN;
            else
                [value, ~] = lvd_CumulativeDeltaVTasks(ind, entries);
            end
        end

        function constraint = getDefaultConstraint(constraintType, lvdData)            
            constraint = GenericMAConstraint(constraintType, LaunchVehicleEvent.empty(1,0), 0, 0, [], [], KSPTOT_BodyInfo.empty(1,0));
        end
    end
end