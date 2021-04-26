classdef TwoBodyImpactPointLatitude < AbstractConstraint
    %TwoBodyImpactPointLongitude Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        normFact = 1;
        event LaunchVehicleEvent
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        evalType(1,1) ConstraintEvalTypeEnum = ConstraintEvalTypeEnum.FixedBounds;
        stateCompType(1,1) ConstraintStateComparisonTypeEnum = ConstraintStateComparisonTypeEnum.Equals;
        stateCompEvent LaunchVehicleEvent
    end
    
    methods
        function obj = TwoBodyImpactPointLatitude(event, lb, ub)
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
            stateLogEntry = stateLog.getLastStateLogForEvent(obj.event);

            value = lvd_TwoBodyImpactPointTasks(stateLogEntry, 'latitude');
            
            if(isnan(value))
                value = 1000; %need to throw in a real number
            end
            
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                stateLogEntryStateComp = stateLog.getLastStateLogForEvent(obj.stateCompEvent).deepCopy();
                
                cartElem = stateLogEntryStateComp.getCartesianElementSetRepresentation();
                cartElem = cartElem.convertToFrame(stateLogEntry.centralBody.getBodyCenteredInertialFrame());
                stateLogEntryStateComp.setCartesianElementSet(cartElem);

                valueStateComp = lvd_TwoBodyImpactPointTasks(stateLogEntryStateComp, 'latitude');

                if(isnan(valueStateComp))
                    valueStateComp = 1000; %need to throw in a real number
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
            type = 'Two-Body Impact Latitude';
        end
        
%         function name = getName(obj)
%             name = sprintf('%s - Event %i', obj.getConstraintType(), obj.event.getEventNum());
%         end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = 'degN';
            lbLim = -90;
            ubLim = 90;
            usesLbUb = true;
            usesCelBody = false;
            usesRefSc = false;
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
            addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = TwoBodyImpactPointLatitude(LaunchVehicleEvent.empty(1,0),0,0);
        end
    end
end