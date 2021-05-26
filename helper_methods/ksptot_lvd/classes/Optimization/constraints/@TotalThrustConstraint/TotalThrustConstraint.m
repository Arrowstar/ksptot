classdef TotalThrustConstraint < AbstractConstraint
    %TotalThrustConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
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
        function obj = TotalThrustConstraint(event, lb, ub)
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
            
            totalThrust = TotalThrustConstraint.getTotalThrust(stateLogEntry);
            value = totalThrust;
                       
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                switch obj.stateCompNode
                    case ConstraintStateComparisonNodeEnum.FinalState
                        stateLogEntryStateComp = stateLog.getLastStateLogForEvent(obj.stateCompEvent);

                    case ConstraintStateComparisonNodeEnum.InitialState
                        stateLogEntryStateComp = stateLog.getFirstStateLogForEvent(obj.stateCompEvent);

                    otherwise
                        error('Unknown event node.');
                end

                valueStateComp = TotalThrustConstraint.getTotalThrust(stateLogEntryStateComp); %it's probably not a bad idea to leave the state here in the original reference frame.
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
            type = 'Total Thrust';
        end
        
%         function name = getName(obj)
%             name = sprintf('%s - Event %i', obj.getConstraintType(), obj.event.getEventNum());
%         end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = 'kN';
            lbLim = 0;
            ubLim = Inf;
            usesLbUb = true;
            usesCelBody = false;
            usesRefSc = false;
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
            addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
        end
    end
    
    methods(Static, Access=private)
        function totalThrust = getTotalThrust(stateLogEntry)
            ut = stateLogEntry.time;
            rVect = stateLogEntry.position;
            vVect = stateLogEntry.velocity;
            
            bodyInfo = stateLogEntry.centralBody;
            tankStates = stateLogEntry.getAllActiveTankStates();
            stageStates = stateLogEntry.stageStates;
            lvState = stateLogEntry.lvState;
            
            dryMass = stateLogEntry.getTotalVehicleDryMass();
            tankStatesMasses = [tankStates.tankMass]';
            
            throttleModel = stateLogEntry.throttleModel;
            steeringModel = stateLogEntry.steeringModel;
            
            altitude = norm(rVect) - bodyInfo.radius;
            pressure = getPressureAtAltitude(bodyInfo, altitude); 
            
            powerStorageStates = stateLogEntry.getAllActivePwrStorageStates();
            storageSoCs = NaN(size(powerStorageStates));
            for(i=1:length(powerStorageStates))
                storageSoCs(i) = powerStorageStates(i).getStateOfCharge();
            end
            
            throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);
            
            [~, totalThrust, ~] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates);
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = TotalThrustConstraint(LaunchVehicleEvent.empty(1,0),0,0);
        end
    end
end