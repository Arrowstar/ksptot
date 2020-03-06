classdef ForceModelPropagator < AbstractPropagator
    %ForceModelPropagator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        forceModels ForceModelsEnum = ForceModelsEnum.getDefaultArrayOfForceModelEnums();
    end
    
    properties(Constant)
        propagatorEnum = PropagatorEnum.ForceModel;
    end
    
    methods
        function obj = ForceModelPropagator()

        end
        
        function [t,y,te,ye,ie] = propagate(obj, integrator, tspan, eventInitStateLogEntry, ...
                                            eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData, ...
                                            tStartPropTime, maxPropTime)
                                        
            %Create function handles
            odefun = obj.getOdeFunctionHandle(eventInitStateLogEntry);
            evtsFunc = obj.getOdeEventsFunctionHandle(eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData);
            odeOutputFun = obj.getOdeOutputFunctionHandle(tStartPropTime, maxPropTime);
            
            %Propagate!
            [t0,y0, ~] = eventInitStateLogEntry.getFirstOrderIntegratorStateRepresentation();

            if(eventInitStateLogEntry.isHoldDownEnabled())
                %Integrate in the body-fixed frame with zero rates
                %For performance reasons
                bodyInfo = eventInitStateLogEntry.centralBody;
                [rVectECEF, vVectECEF] = getFixedFrameVectFromInertialVect(t0, y0(1:3)', bodyInfo, y0(4:6)');
                y0 = [rVectECEF', vVectECEF', y0(:,7:end)];

                [t,y,te,ye,ie] = integrator.integrate(odefun, tspan, y0, evtsFunc, odeOutputFun);

                [rVectECI, vVectECI] = getInertialVectFromFixedFrameVect(t, y(:,1:3)', bodyInfo, y(:,4:6)');
                y = [rVectECI', vVectECI', y(:,7:end)];

                if(~isempty(ye))
                    [rVectECIe, vVectECIe] = getInertialVectFromFixedFrameVect(te, ye(:,1:3)', bodyInfo, ye(:,4:6)');
                    ye = [rVectECIe', vVectECIe', ye(:,7:end)];
                end
            else
                [t,y,te,ye,ie] = integrator.integrate(odefun, tspan, y0, evtsFunc, odeOutputFun);
            end   
        end
        
        function odeFH = getOdeFunctionHandle(obj, eventInitStateLogEntry)
            tankStates = eventInitStateLogEntry.getAllActiveTankStates();
            dryMass = eventInitStateLogEntry.getTotalVehicleDryMass();
            odeFH = @(t,y) ForceModelPropagator.odefun(t,y, eventInitStateLogEntry, tankStates, dryMass, obj.forceModels);
        end
        
        function odeEventsFH = getOdeEventsFunctionHandle(~, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData)
            odeEventsFH = @(t,y) AbstractPropagator.odeEvents(t,y, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData);
        end
        
        function odeOutputFH = getOdeOutputFunctionHandle(~, tStartPropTime, maxPropTime)
            odeOutputFH = @(t,y,flag) ForceModelPropagator.odeOutput(t,y,flag, tStartPropTime, maxPropTime);
        end
        
        function [value,isterminal,direction,causes] = callEventsFcn(obj, odeEventsFun, stateLogEntry)
            [t,y, ~] = stateLogEntry.getFirstOrderIntegratorStateRepresentation();
            [value,isterminal,direction,causes] = odeEventsFun(t,y);
        end
        
        function openOptionsDialog(obj)
            fms = obj.forceModels;
            initSelInds = [];
            for(i=1:length(fms))
                if(fms(i).canBeDisabled)
                    initSelInds(end+1) = ForceModelsEnum.getIndOfDisablableListboxStrsForModel(fms(i).model); %#ok<AGROW>
                end
            end

            [Selection,ok] = listdlgARH('ListString',ForceModelsEnum.getListBoxStrsOfDisablableModels(), ...
                                        'SelectionMode', 'multiple', ...
                                        'ListSize', [300, 300], ...
                                        'Name', 'Select Force Models', ...
                                        'PromptString', {'Select the Force Models you wish to have enabled during this','event.  Gravity is always enabled.  Disabling Thrust during','periods of coasting may improve performance considerably.'}, ...
                                        'InitialValue', initSelInds);

            if(ok == 1)
                m = ForceModelsEnum.getEnumsOfDisablableForceModels();
                obj.forceModels = [ForceModelsEnum.getAllForceModelsThatCannotBeDisabled(), m(Selection)'];
            end
        end
    end

    methods(Static, Access=private)
        %%%
        %ODE Function
        %%%
        function dydt = odefun(t,y, eventInitStateLogEntry, tankStates, dryMass, fmEnums)
            bodyInfo = eventInitStateLogEntry.centralBody;
            if(isstruct(bodyInfo.celBodyData) || isempty(bodyInfo.celBodyData))
                bodyInfo.celBodyData = eventInitStateLogEntry.celBodyData;
            end
            
            [ut, rVect, vVect, tankStatesMasses] = AbstractPropagator.decomposeIntegratorTandY(t,y);
            altitude = norm(rVect) - bodyInfo.radius;

            stageStates = eventInitStateLogEntry.stageStates;
            lvState = eventInitStateLogEntry.lvState;
            t2tConnStates = lvState.t2TConns;

            throttleModel = eventInitStateLogEntry.throttleModel;
            steeringModel = eventInitStateLogEntry.steeringModel;

            holdDownEnabled = eventInitStateLogEntry.isHoldDownEnabled();

            tankMassDotsT2TConns = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, tankStatesMasses, t2tConnStates);

            dydt = zeros(length(y),1);
            if(holdDownEnabled)
                pressure = getPressureAtAltitude(bodyInfo, altitude);
                throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo);

                tankMassDotsEngines = eventInitStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel);

                tankMassDots = tankMassDotsEngines + tankMassDotsT2TConns;

                %launch clamp is enabled, only motion is circular motion
                %(fixed to body)
                %In this case, we are integrating in the body-fixed frame, 
                %so all rates are effectively zero        
                dydt(1:3) = [0;0;0]; 
                dydt(4:6) = [0;0;0];
                dydt(7:end) = tankMassDots;
            else
                %launch clamp disabled, propagate like normal
                if(altitude <= 0 && any(fmEnums == ForceModelsEnum.Normal))
                    rswVVect = rotateVectorFromEciToRsw(vVect, rVect, vVect);
                    rswVVect(1) = 0; %kill vertical velocity because we don't want to go throught the surface of the planet
                    vVect = rotateVectorFromRsw2Eci(rswVVect, rVect, vVect);
                end

                aero = eventInitStateLogEntry.aero;
                thirdBodyGravity = eventInitStateLogEntry.thirdBodyGravity;

                totalMass = dryMass + sum(tankStatesMasses);

                if(totalMass > 0)
                    [forceSum, tankMassDotsForceModels] = TotalForceModel.getForce(fmEnums, ut, rVect, vVect, totalMass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity);
                    accelVect = forceSum/totalMass; %F = dp/dt = d(mv)/dt = m*dv/dt + v*dm/dt, but since the thrust force causes us to shed mass, we actually account for the v*dm/dt term there and therefore don't need it!  See: https://en.wikipedia.org/wiki/Variable-mass_system         

                    tankMassDots = tankMassDotsForceModels + tankMassDotsT2TConns;

                    dydt(7:end) = tankMassDots;
                else
                    accelVect = zeros(3,1);
                    dydt(7:end) = zeros(size(tankStates));
                end

                dydt(1:3) = vVect'; 
                dydt(4:6) = accelVect;
            end
        end
        
        %%%
        %ODE Output
        %%%
        function status = odeOutput(t,y,flag, intStartTime, maxIntegrationDuration)
            integrationDuration = toc(intStartTime);

            status = 0;
            if(integrationDuration > maxIntegrationDuration)
                status = 1;
            end
            
%             disp(t);
        end
    end
end