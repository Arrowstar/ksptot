classdef PositionContinuityConstraint < AbstractConstraint
    %PositionContinuityConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        normFact = 1;
        event LaunchVehicleEvent
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
    end
    
    methods
        function obj = PositionContinuityConstraint(event)
            obj.event = event; 
            
            obj.id = rand();
        end
        
        function [lb, ub] = getBounds(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function [c, ceq, value, lwrBnd, uprBnd, type, eventNum] = evalConstraint(obj, stateLog, celBodyData)           
            type = obj.getConstraintType();
            
            stateLogEntries = stateLog.getAllStateLogEntriesForEvent(obj.event);
            if(length(stateLogEntries) > 2 && obj.event.getNumberOfActions() > 0)
                stateLogEntry1 = stateLogEntries(end-1);
                stateLogEntry2 = stateLogEntries(end);

                sunFrame = BodyCenteredInertialFrame(celBodyData.sun, celBodyData);
                cartElemSet1 = stateLogEntry1.getCartesianElementSetRepresentation().convertToFrame(sunFrame);
                cartElemSet2 = stateLogEntry2.getCartesianElementSetRepresentation().convertToFrame(sunFrame);
                
                value = norm(cartElemSet2.rVect - cartElemSet1.rVect);
                
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
            type = 'Position Continuity';
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
            addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~)            
            constraint = PositionContinuityConstraint(LaunchVehicleEvent.empty(1,0));
        end
    end
end