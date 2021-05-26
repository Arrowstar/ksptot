classdef AddDeltaVAction < AbstractEventAction
    %AddDeltaVAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        deltaVVect(3,1) double = [0;0;0]; %store as km/s
        frame(1,1) DeltaVFrameEnum = DeltaVFrameEnum.Inertial;
        useDeltaMass(1,1) logical = false;
        
        optVar AbstractOptimizationVariable
    end
    
    methods
        function obj = AddDeltaVAction(deltaVVect, frame, useDeltaMass)
            if(nargin > 0)
                obj.deltaVVect = deltaVVect;
                obj.frame = frame;
                obj.useDeltaMass = useDeltaMass;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            
            if(obj.frame == DeltaVFrameEnum.Inertial)
                dvKmsVect = obj.deltaVVect;
                
            elseif(obj.frame == DeltaVFrameEnum.OrbitNtw)
                dVVectECI = getNTW2ECIdvVect(obj.deltaVVect, newStateLogEntry.position, newStateLogEntry.velocity);
                dvKmsVect = dVVectECI;
                
            else
                error('Unknown reference frame found while executing action AddDeltaVAction.');
            end
            
            newStateLogEntry.velocity = newStateLogEntry.velocity + dvKmsVect;
            
            if(obj.useDeltaMass)
                tankStates = newStateLogEntry.getAllActiveTankStates();
                tankStatesMasses = [tankStates.tankMass];
                stageStates = newStateLogEntry.stageStates;
                lvState = newStateLogEntry.lvState;
                ut = newStateLogEntry.time;
                rVect = newStateLogEntry.position;
                vVect = newStateLogEntry.velocity;
                bodyInfo = newStateLogEntry.centralBody;
                steeringModel = newStateLogEntry.steeringModel;
                
                altitude = newStateLogEntry.altitude;
                pressure = getPressureAtAltitude(bodyInfo, altitude);
                throttle = 1.0;
                
                powerStorageStates = newStateLogEntry.getAllActivePwrStorageStates();
                storageSoCs = NaN(size(powerStorageStates));
                for(j=1:length(powerStorageStates))
                    storageSoCs(j) = powerStorageStates(j).getStateOfCharge();
                end

                [tankMDots, totalThrust, ~, ~] = newStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates);
                
                if(abs(sum(tankMDots)) > 0)
                    tankMDotsKgS = tankMDots * 1000;
                    totalMDotKgS = sum(tankMDotsKgS);
                    totalThrustN = totalThrust * 1000;
                    effIsp = totalThrustN / (getG0() * abs(totalMDotKgS)); %sec
                    
                    dvVectMag = norm(dvKmsVect);
                    m0 = newStateLogEntry.getTotalVehicleMass();
                    m1 = revRocketEqn(m0, effIsp, dvVectMag);
                    deltaMassMT = m0 - m1;

                    deltaMassPerTankMT = deltaMassMT * (abs(tankMDots) / abs(sum(tankMDots)));

                    for(i=1:length(tankStates))
                        tankStates(i).setTankMass(tankStates(i).getTankMass() - deltaMassPerTankMT(i));
                    end
                end
            end
        end
        
        function initAction(obj, initialStateLogEntry)
            %none
        end
        
        function name = getName(obj)           
            name = sprintf('Add Delta-V ([%0.3f %0.3f %0.3f] m/s %s)', obj.deltaVVect(1)*1000, obj.deltaVVect(2)*1000, obj.deltaVVect(3)*1000, obj.frame.nameStr);
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
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
            
            if(not(isempty(obj.optVar)))
                tf = any(obj.optVar.getUseTfForVariable());
                vars(end+1) = obj.optVar;
            end
        end
        
        function data = getUploadDvToKspData(obj, stateLogEntry)  
            time = stateLogEntry.time;
            rVect = stateLogEntry.position;
            vVect = stateLogEntry.velocity;
            
            if(obj.frame == DeltaVFrameEnum.Inertial)
                deltaVNTW = 1000*getNTWdvVect(obj.deltaVVect, rVect(:), vVect(:));
                
            elseif(obj.frame == DeltaVFrameEnum.OrbitNtw)
                deltaVNTW = 1000*obj.deltaVVect;
                
            else
                error('Unknown reference frame found while executing action AddDeltaVAction.');
            end
            
            data(1) = 0;
            data(2) = time;
            data(3) = deltaVNTW(1);
            data(4) = deltaVNTW(2);
            data(5) = deltaVNTW(3);
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_AddDeltaVActionGUI(action, lv.lvdData);
        end
    end
end