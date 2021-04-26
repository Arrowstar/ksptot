classdef GroundObjElConstraint < AbstractConstraint
    %GroundObjElConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        normFact = 1;
        groundObj LaunchVehicleGroundObject
        event LaunchVehicleEvent
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        evalType(1,1) ConstraintEvalTypeEnum = ConstraintEvalTypeEnum.FixedBounds;
        stateCompType(1,1) ConstraintStateComparisonTypeEnum = ConstraintStateComparisonTypeEnum.Equals;
        stateCompEvent LaunchVehicleEvent
    end
    
    methods
        function obj = GroundObjElConstraint(groundObj, event, lb, ub)
            obj.groundObj = groundObj;
            obj.event = event;
            obj.lb = lb;
            obj.ub = ub;   
            
             obj.id = rand();
        end
        
        function [lb, ub] = getBounds(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function [c, ceq, value, lwrBnd, uprBnd, type, eventNum, stateLogEntryStateComp] = evalConstraint(obj, stateLog, celBodyData)           
            type = obj.getConstraintType();
            stateLogEntry = stateLog.getLastStateLogForEvent(obj.event);
            
            [value, ~] = lvd_GrdObjTasks(stateLogEntry, 'elevation', obj.groundObj);         
            
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                stateLogEntryStateComp = stateLog.getLastStateLogForEvent(obj.stateCompEvent).deepCopy();
                
                cartElem = stateLogEntryStateComp.getCartesianElementSetRepresentation();
                cartElem = cartElem.convertToFrame(stateLogEntry.centralBody.getBodyCenteredInertialFrame());
                stateLogEntryStateComp.setCartesianElementSet(cartElem);

                [valueStateComp, ~] = lvd_GrdObjTasks(stateLogEntryStateComp, 'elevation', obj.groundObj);  
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
        
        function tf = usesGroundObj(obj, grdObj)
            tf = obj.groundObj == grdObj;
        end
        
        function tf = canUseSparseOutput(obj)
            tf = true;
        end
        
        function event = getConstraintEvent(obj)
            event = obj.event;
        end
        
        function type = getConstraintType(obj)
            type = 'Ground Object Elevation';
        end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = 'deg';
            lbLim = -90;
            ubLim = 90;
            usesLbUb = true;
            usesCelBody = false;
            usesRefSc = false;
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
            if(lvdData.groundObjs.getNumGroundObj() >= 1)
                addConstraintTf = lvd_EditGroundObjConstraintGUI(obj, lvdData);
            else
                errordlg('There are currently no ground objects in this scenario.  Add at least one new ground object first.');
                
                addConstraintTf = false;
            end
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = GroundObjElConstraint(LaunchVehicleGroundObject.empty(1,0), LaunchVehicleEvent.empty(1,0), 0, 0);
        end
    end
end