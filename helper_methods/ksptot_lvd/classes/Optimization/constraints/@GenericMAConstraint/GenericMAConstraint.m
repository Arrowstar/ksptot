classdef GenericMAConstraint < AbstractConstraint
    %GenericMAConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        constraintType char = '';
        normFact = 1;
        event LaunchVehicleEvent
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        evalType(1,1) ConstraintEvalTypeEnum = ConstraintEvalTypeEnum.FixedBounds;
        stateCompType(1,1) ConstraintStateComparisonTypeEnum = ConstraintStateComparisonTypeEnum.Equals;
        stateCompEvent LaunchVehicleEvent
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
            
            stateLogEntry = stateLog.getLastStateLogForEvent(obj.event);
            type = obj.constraintType;
            
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
                    
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                stateLogEntryStateComp = stateLog.getLastStateLogForEvent(obj.stateCompEvent).deepCopy();
                cartElem = stateLogEntryStateComp.getCartesianElementSetRepresentation().convertToFrame(frame);
                stateLogEntryStateComp.setCartesianElementSet(cartElem);
                
%                 stateLogEntryStateCompMA = stateLogEntryStateComp.getMAFormattedStateLogMatrix(true);
%                 valueStateComp = ma_getDepVarValueUnit(1, stateLogEntryStateCompMA, type, 0, refBodyId, oscId, stnId, propNames, maData, celBodyData, false);

                valueStateComp = obj.getValueForConstraint(stateLogEntryStateComp, type, maTaskList, refBodyId, celBodyData, frame);
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
            addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
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
                [value, ~] = lvd_getDepVarValueUnit(1, stateLogEntry, type, refBodyId, celBodyData, false, frame); %need to update!
            end
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(constraintType, lvdData)            
            constraint = GenericMAConstraint(constraintType, LaunchVehicleEvent.empty(1,0), 0, 0, [], [], KSPTOT_BodyInfo.empty(1,0));
        end
    end
end