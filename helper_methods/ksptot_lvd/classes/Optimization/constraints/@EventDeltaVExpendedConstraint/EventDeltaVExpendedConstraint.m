classdef EventDeltaVExpendedConstraint < AbstractConstraint
    %EventDeltaVConstraint Summary of this class goes here
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
        function obj = EventDeltaVExpendedConstraint(event, lb, ub)
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

            deltaVExpended = EventDeltaVExpendedConstraint.computeTotalDeltaV(stateLog, obj.event);
            value = deltaVExpended;
                       
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)               
                valueStateComp = EventDeltaVExpendedConstraint.computeTotalDeltaV(stateLog, obj.stateCompEvent);
                
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
            tf = false;
        end
        
        function event = getConstraintEvent(obj)
            event = obj.event;
        end
        
        function type = getConstraintType(obj)
            type = 'Event Delta-V Expended';
        end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = 'km/s';
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
        function deltaVExpended = computeTotalDeltaV(stateLog, event)
            subStateLog = stateLog.getAllStateLogEntriesForEvent(event);

            if(length(subStateLog) > 1)
                g0 = getG0();
                deltaVExpended = 0;
                
                for(i=1:length(subStateLog)-1) %#ok<NO4LP>
                    stateLogEntry1 = subStateLog(i);
                    stateLogEntry2 = subStateLog(i+1);

                    ut = stateLogEntry1.time;
                    rVect = stateLogEntry1.position;
                    vVect = stateLogEntry1.velocity;

                    bodyInfo = stateLogEntry1.centralBody;
                    tankStates = stateLogEntry1.getAllActiveTankStates();
                    stageStates = stateLogEntry1.stageStates;
                    lvState = stateLogEntry1.lvState;

                    dryMass = stateLogEntry1.getTotalVehicleDryMass();
                    tankStatesMasses = [tankStates.tankMass]';
                    
                    throttleModel = stateLogEntry1.throttleModel;
                    steeringModel = stateLogEntry1.steeringModel;

                    altitude = norm(rVect) - bodyInfo.radius;
                    pressure = getPressureAtAltitude(bodyInfo, altitude); 

                    powerStorageStates = stateLogEntry1.getAllActivePwrStorageStates();
                    storageSoCs = NaN(size(powerStorageStates));
                    for(j=1:length(powerStorageStates))
                        storageSoCs(j) = powerStorageStates(j).getStateOfCharge();
                    end
                    
                    throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);

                    [tankMDots, totalThrust, ~] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates);

                    if(abs(sum(tankMDots)) > 0)
                        tankMDotsKgS = tankMDots * 1000;
                        totalMDotKgS = sum(tankMDotsKgS); %should be negative
                        totalThrustN = totalThrust * 1000;
                        effIsp = totalThrustN / (getG0() * abs(totalMDotKgS)); %sec

                        totalMass1 = dryMass + stateLogEntry1.getTotalVehiclePropMass();
                        totalMass2 = dryMass + stateLogEntry2.getTotalVehiclePropMass();
                        
                        if(totalMass1 > totalMass2 && stateLogEntry1.time < stateLogEntry2.time)
                            deltaVExpended = deltaVExpended + (g0 * effIsp * log(totalMass1 / totalMass2))/1000; %need to convert to km/s
                        end
                    end
                end
            else
                deltaVExpended = 0;
            end
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = EventDeltaVExpendedConstraint(LaunchVehicleEvent.empty(1,0),0,0);
        end
    end
end