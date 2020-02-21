classdef PositionContinuityConstraintY < AbstractConstraint
    %PositionContinuityConstraintY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        normFact = 1;
        event LaunchVehicleEvent
        constraintEvent LaunchVehicleEvent
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
    end
    
    methods
        function obj = PositionContinuityConstraintY(event, constraintEvent)
            obj.event = event; 
            obj.constraintEvent = constraintEvent;
            
            obj.id = rand();
        end
        
        function [lb, ub] = getBounds(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function [c, ceq, value, lwrBnd, uprBnd, type, eventNum] = evalConstraint(obj, stateLog, celBodyData)           
            type = obj.getConstraintType();
            
            if(not(isempty(obj.event)) && not(isempty(obj.constraintEvent)))
                stateLogEntriesEvt = stateLog.getAllStateLogEntriesForEvent(obj.event);
                stateLogEntriesConstrEvt = stateLog.getAllStateLogEntriesForEvent(obj.constraintEvent);

                topLevelBodyInfo = getTopLevelCentralBody(celBodyData);
                frame = BodyCenteredInertialFrame(topLevelBodyInfo, celBodyData);
                cartElemSet1 = stateLogEntriesEvt(end).getCartesianElementSetRepresentation().convertToFrame(frame);
                cartElemSet2 = stateLogEntriesConstrEvt(end).getCartesianElementSetRepresentation().convertToFrame(frame);

                value = cartElemSet2.rVect - cartElemSet1.rVect;
                value = value(2);

                c = [];
                ceq = value;
            else
                c = [];
                ceq = [];
                value = 0;
            end
            
            c = c/obj.normFact;
            ceq = ceq/obj.normFact;  
            
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
            type = 'Position Continuity (Y)';
        end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = 'km';
            lbLim = 0;
            ubLim = 0;
            usesLbUb = false;
            usesCelBody = false;
            usesRefSc = false;
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
            addConstraintTf = lvd_EditContinuityConstraintGUI(obj, lvdData);
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~)            
            constraint = PositionContinuityConstraintY(LaunchVehicleEvent.empty(1,0), LaunchVehicleEvent.empty(1,0));
        end
    end
end