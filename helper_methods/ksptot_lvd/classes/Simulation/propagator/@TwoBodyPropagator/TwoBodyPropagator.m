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
            cartState = eventInitStateLogEntry.getCartesianElementSetRepresentation();
            kepState = cartState.convertToKeplerianElementSet();
            [t0FirstOrder,y0FirstOrder, ~] = eventInitStateLogEntry.getFirstOrderIntegratorStateRepresentation();
            [~, ~, ~, tankStates] = AbstractPropagator.decomposeIntegratorTandY(t0FirstOrder, y0FirstOrder);
            
            y0 = [kepState.getMeanAnomaly(), tankStates];
            
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
            
            cartState = eventInitStateLogEntry.getCartesianElementSetRepresentation();
            kepState = cartState.convertToKeplerianElementSet();

            n = kepState.getMeanMotion();
            
            odeFH = @(t,y) TwoBodyPropagator.odefun(t,y, n, eventInitStateLogEntry, tankStates);
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
            [value,isterminal,direction,causes] = odeEventsFun(t,y);
        end
        
        function openOptionsDialog(obj)
            %nothing at the moment
        end
    end

    methods(Static, Access=private)
        %%%
        %ODE Function
        %%%
        function dydt = odefun(t,y, n, eventInitStateLogEntry, tankStates)
            [~, ~, tankStatesMasses] = TwoBodyPropagator.decomposeIntegratorTandY(t,y);

            lvState = eventInitStateLogEntry.lvState;
            t2tConnStates = lvState.t2TConns;

            holdDownEnabled = eventInitStateLogEntry.isHoldDownEnabled();

            tankMassDotsT2TConns = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, tankStatesMasses, t2tConnStates);
            tankMassDots = tankMassDotsT2TConns;
            
            dydt = zeros(length(y),1);
            if(holdDownEnabled)
                %launch clamp is enabled, set mean motion to zero
                dydt(1) = 0;
                dydt(2:end) = tankMassDots;
            else
                %launch clamp disabled, propagate like normal
                dydt(1) = n;
                dydt(2:end) = tankMassDots;
            end
        end
        
        %%%
        %ODE Output
        %%%
        function status = odeOutput(~,~,~, intStartTime, maxIntegrationDuration, eventInitStateLogEntry, plugins)
            plugins.executePluginsAfterTimeStepOdeOutputFcn(t,y,flag, eventInitStateLogEntry);
            
            integrationDuration = toc(intStartTime);

            status = 0;
            if(integrationDuration > maxIntegrationDuration)
                status = 1;
            end
        end
    end
    
    methods(Static, Access=protected)
        %%%
        %ODE Events
        %%%
        function [value,isterminal,direction, causes] = odeEvents(t,y, sma, ecc, inc, raan, arg, gmu, eventInitStateLogEntry, evtTermCond, termCondDir, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData)
            [~, mean, tankStatesMasses] = TwoBodyPropagator.decomposeIntegratorTandY(t,y);
            tru = computeTrueAnomFromMean(mean, ecc);
            [rVect, vVect] = getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu);
            y = [rVect(:); vVect(:); tankStatesMasses(:)];

            [value,isterminal,direction, causes] = AbstractPropagator.odeEvents(t,y, eventInitStateLogEntry, evtTermCond, termCondDir, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData);
        end
        
        function [ut, mean, tankStates] = decomposeIntegratorTandY(t,y)
            ut = t;
            mean = y(1);
            tankStates = y(2:end);
        end
    end
end