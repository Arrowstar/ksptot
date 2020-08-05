classdef TwoBodyPropagator < AbstractPropagator
    %TwoBodyPropagator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        propagatorEnum = PropagatorEnum.TwoBody;
    end
    
    methods
        function obj = TwoBodyPropagator()

        end
        
        function [t,y,te,ye,ie] = propagate(obj, integrator, tspan, eventInitStateLogEntry, ...
                                            eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData, ...
                                            tStartPropTime, maxPropTime)
            plugins = eventInitStateLogEntry.lvdData.plugins;    
                                        
            %Create function handles
            odefun = obj.getOdeFunctionHandle(eventInitStateLogEntry);
            evtsFunc = obj.getOdeEventsFunctionHandle(eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData);
            odeOutputFun = obj.getOdeOutputFunctionHandle(tStartPropTime, maxPropTime, eventInitStateLogEntry, plugins);
            
            %Propagate!
            numTankStates = eventInitStateLogEntry.getNumActiveTankStates();
            numPwrStorageStates = eventInitStateLogEntry.getNumActivePwrStorageStates();
            
            cartState = eventInitStateLogEntry.getCartesianElementSetRepresentation();
            kepState = cartState.convertToKeplerianElementSet();
            [t0FirstOrder,y0FirstOrder, ~, ~] = eventInitStateLogEntry.getFirstOrderIntegratorStateRepresentation();
            [~, ~, ~, tankStates, pwrStorageStates] = AbstractPropagator.decomposeIntegratorTandY(t0FirstOrder, y0FirstOrder, numTankStates, numPwrStorageStates);
            
            y0 = [kepState.getMeanAnomaly(), tankStates, pwrStorageStates];
            
            [t,y,te,ye,ie] = integrator.integrate(odefun, tspan, y0, evtsFunc, odeOutputFun);  
            
            onesArr = ones(1,length(t));
            sma = kepState.sma * onesArr;
            ecc = kepState.ecc * onesArr;
            inc = kepState.inc * onesArr;
            raan = kepState.raan * onesArr;
            arg = kepState.arg * onesArr;
            
            bodyInfo = kepState.frame.getOriginBody();
            gmu = bodyInfo.gm * onesArr;

            mean = y(:,1);
            mean = mean(:)';
            tru = computeTrueAnomFromMean(mean, ecc);
            tru = tru(:)';
            [rVect, vVect] = vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu);
            
            if(eventInitStateLogEntry.isHoldDownEnabled())
                t0 = t(1);
                rVect0 = rVect(:,1);
                vVect0 = vVect(:,1);
                
                [rVectECEF, vVectECEF] = getFixedFrameVectFromInertialVect(t0, rVect0, bodyInfo, vVect0);
                rVectECEF = repmat(rVectECEF,1,length(t));
                vVectECEF = repmat(vVectECEF,1,length(t));
                
                [rVectECI, vVectECI] = getInertialVectFromFixedFrameVect(t', rVectECEF, bodyInfo, vVectECEF);
                ynew = [rVectECI', vVectECI', y(:,2:end)];
                
            else
                ynew = [rVect', vVect', y(:,2:end)];
            end
            
            y = ynew;
            
            if(not(isempty(te)))
                ye = ynew(t == te,:);
            end
        end
        
        function odeFH = getOdeFunctionHandle(obj, eventInitStateLogEntry)
            tankStates = eventInitStateLogEntry.getAllActiveTankStates();
            pwrStorageStates = eventInitStateLogEntry.getAllActivePwrStorageStates();
            
            cartState = eventInitStateLogEntry.getCartesianElementSetRepresentation();
            kepState = cartState.convertToKeplerianElementSet();

            sma = kepState.sma;
            ecc = kepState.ecc;
            inc = kepState.inc;
            raan = kepState.raan;
            arg = kepState.arg;
            
            gmu = kepState.frame.getOriginBody().gm;
            
            n = kepState.getMeanMotion();
            
            odeFH = @(t,y) TwoBodyPropagator.odefun(t,y, n, sma, ecc, inc, raan, arg, gmu, eventInitStateLogEntry, tankStates, pwrStorageStates);
        end
        
        function odeEventsFH = getOdeEventsFunctionHandle(~, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData)
            cartState = eventInitStateLogEntry.getCartesianElementSetRepresentation();
            kepState = cartState.convertToKeplerianElementSet();

            sma = kepState.sma;
            ecc = kepState.ecc;
            inc = kepState.inc;
            raan = kepState.raan;
            arg = kepState.arg;
            
            gmu = kepState.frame.getOriginBody().gm;
            
            odeEventsFH = @(t,y) TwoBodyPropagator.odeEvents(t,y, sma, ecc, inc, raan, arg, gmu, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData);
        end
        
        function odeOutputFH = getOdeOutputFunctionHandle(~, tStartPropTime, maxPropTime, eventInitStateLogEntry, plugins)
            odeOutputFH = @(t,y,flag) TwoBodyPropagator.odeOutput(t,y,flag, tStartPropTime, maxPropTime, eventInitStateLogEntry, plugins);
        end
        
        function [value,isterminal,direction,causes] = callEventsFcn(obj, odeEventsFun, stateLogEntry)
            [t,y, ~] = stateLogEntry.getFirstOrderIntegratorStateRepresentation();

            numTankStates = stateLogEntry.getNumActiveTankStates();
            numPwrStorageStates = stateLogEntry.getNumActivePwrStorageStates();
            [~, rVect, vVect, tankStatesMasses, pwrStorageSocs] = AbstractPropagator.decomposeIntegratorTandY(t,y, numTankStates, numPwrStorageStates);
            gmu = stateLogEntry.centralBody.gm;
            
            [~, ecc, ~, ~, ~, tru] = getKeplerFromState(rVect, vVect, gmu);
            mean = computeMeanFromTrueAnom(tru, ecc);
            
            yNew = [mean, tankStatesMasses(:)', pwrStorageSocs(:)'];
            
            [value,isterminal,direction,causes] = odeEventsFun(t,yNew);
        end
        
        function openOptionsDialog(obj)
            %nothing at the moment
        end

        function tf = canProduceThrust(obj)
            tf = false;
        end
    end

    methods(Static, Access=private)
        %%%
        %ODE Function
        %%%
        function dydt = odefun(t,y, n, sma, ecc, inc, raan, arg, gmu, eventInitStateLogEntry, tankStates, powerStorageStates)
            [ut, ~, tankStatesMasses, storageSoCs] = TwoBodyPropagator.decomposeIntegratorTandY(t,y, length(tankStates), length(powerStorageStates));

            lvState = eventInitStateLogEntry.lvState;
            t2tConnStates = lvState.t2TConns;

            holdDownEnabled = eventInitStateLogEntry.isHoldDownEnabled();

            tankMassDotsT2TConns = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, tankStatesMasses, t2tConnStates);
            tankMassDots = tankMassDotsT2TConns;
            
            if(not(isempty(powerStorageStates)))
                bodyInfo = eventInitStateLogEntry.centralBody;
                if(isstruct(bodyInfo.celBodyData) || isempty(bodyInfo.celBodyData))
                    bodyInfo.celBodyData = eventInitStateLogEntry.celBodyData;
                end

                stageStates = eventInitStateLogEntry.stageStates;
                steeringModel = eventInitStateLogEntry.steeringModel;

                mean = y(1);
                tru = computeTrueAnomFromMean(mean, ecc); 
                [rVect, vVect] = getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu);
                storageRates = LaunchVehicleStateLogEntry.getStorageChargeRatesDueToSourcesSinks(storageSoCs, powerStorageStates, stageStates, ut, rVect(:), vVect(:), bodyInfo, steeringModel);
                
            else
                storageRates = [];
            end
            
            dydt = zeros(length(y),1);
            if(holdDownEnabled)
                %launch clamp is enabled, set mean motion to zero
                dydt(1) = 0;
            else
                %launch clamp disabled, propagate like normal
                dydt(1) = n;
            end
            
            dydt(2:1+length(tankMassDots)) = tankMassDots;
            dydt(1+length(tankMassDots)+1 : 1+length(tankMassDots)+length(storageRates)) = storageRates;
        end
        
        %%%
        %ODE Output
        %%%
        function status = odeOutput(t,y,flag, intStartTime, maxIntegrationDuration, eventInitStateLogEntry, plugins)
            plugins.executePluginsAfterTimeStepOdeOutputFcn(t,y,flag, eventInitStateLogEntry);
            
            integrationDuration = toc(intStartTime);

            status = 0;
            if(integrationDuration > maxIntegrationDuration)
                status = 1;
            end
        end
    end
    
    methods(Static)
        %%%
        %ODE Events
        %%%
        function [value,isterminal,direction, causes] = odeEvents(t,y, sma, ecc, inc, raan, arg, gmu, eventInitStateLogEntry, evtTermCond, termCondDir, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData)
            numTankStates = eventInitStateLogEntry.getNumActiveTankStates();
            numPwrStorageStates = eventInitStateLogEntry.getNumActivePwrStorageStates();
            [~, mean, tankStatesMasses, pwrStorageSocs] = TwoBodyPropagator.decomposeIntegratorTandY(t,y, numTankStates, numPwrStorageStates);
            tru = computeTrueAnomFromMean(mean, ecc);
            [rVect, vVect] = getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu);
            y = [rVect(:); vVect(:); tankStatesMasses(:); pwrStorageSocs(:)]';

            [value,isterminal,direction, causes] = AbstractPropagator.odeEvents(t,y, eventInitStateLogEntry, evtTermCond, termCondDir, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData);
        end
        
        function [ut, mean, tankStates, storageSoCs] = decomposeIntegratorTandY(t,y, numTankMasses, numPwrStorageStates)
            ut = t;
            mean = y(1);
            tankStates = y(2:1+numTankMasses);
            storageSoCs = y(1+numTankMasses+1 : 1+numTankMasses+numPwrStorageStates);
        end
    end
end