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
                                       
            plugins = eventInitStateLogEntry.lvdData.plugins;         

            %Get initial states
            [t0,y0, ~] = eventInitStateLogEntry.getFirstOrderIntegratorStateRepresentation();
            tankStates = eventInitStateLogEntry.getAllActiveTankStates();
            pwrStorageStates = eventInitStateLogEntry.getAllActivePwrStorageStates();

            %Get scale factors
            [tStar, lStar, vStar, ~, mStar, ~, cStar, ~] = ForceModelPropagator.getScaleFactors(eventInitStateLogEntry);

            %Scale tspan
            tspanS = tspan / tStar;

            %Create function handles
            odefun = obj.getOdeFunctionHandle(eventInitStateLogEntry);
            evtsFunc = obj.getOdeEventsFunctionHandle(eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData);
            odeOutputFun = obj.getOdeOutputFunctionHandle(tStartPropTime, maxPropTime, eventInitStateLogEntry, plugins);
            
            %Propagate!
            if(eventInitStateLogEntry.isHoldDownEnabled())
                %Integrate in the body-fixed frame with zero rates
                %For performance reasons
                bodyInfo = eventInitStateLogEntry.centralBody;
                [rVectECEF, vVectECEF] = getFixedFrameVectFromInertialVect(t0, y0(1:3)', bodyInfo, y0(4:6)');
                y0 = [rVectECEF', vVectECEF', y0(:,7:end)];

                [~, yS0] = ForceModelPropagator.scaleTAndY(t0,y0, lStar, tStar, vStar, mStar, cStar, tankStates, pwrStorageStates);
                [tS,yS,teS,yeS,ie] = integrator.integrate(odefun, tspanS, yS0, evtsFunc, odeOutputFun);
                [t,y,te,ye] = ForceModelPropagator.unscaleOdeResults(tS, yS, teS, yeS, lStar, tStar, vStar, mStar, cStar, tankStates, pwrStorageStates);

                [rVectECI, vVectECI] = getInertialVectFromFixedFrameVect(t, y(:,1:3)', bodyInfo, y(:,4:6)');
                y = [rVectECI', vVectECI', y(:,7:end)];

                if(~isempty(ye))
                    [rVectECIe, vVectECIe] = getInertialVectFromFixedFrameVect(te, ye(:,1:3)', bodyInfo, ye(:,4:6)');
                    ye = [rVectECIe', vVectECIe', ye(:,7:end)];
                end

            else
                [~, yS0] = ForceModelPropagator.scaleTAndY(t0,y0, lStar, tStar, vStar, mStar, cStar, tankStates, pwrStorageStates);
                [tS,yS,teS,yeS,ie] = integrator.integrate(odefun, tspanS, yS0, evtsFunc, odeOutputFun);
                [t,y,te,ye] = ForceModelPropagator.unscaleOdeResults(tS, yS, teS, yeS, lStar, tStar, vStar, mStar, cStar, tankStates, pwrStorageStates);
            end   
        end
        
        function odeFH = getOdeFunctionHandle(obj, eventInitStateLogEntry)
            tankStates = eventInitStateLogEntry.getAllActiveTankStates();
            dryMass = eventInitStateLogEntry.getTotalVehicleDryMass();
            pwrStorageStates = eventInitStateLogEntry.getAllActivePwrStorageStates();
            
            [tStar, lStar, vStar, aStar, mStar, mDotStar, cStar, cDotStar] = ForceModelPropagator.getScaleFactors(eventInitStateLogEntry);

            % odeFH = @(t,y) ForceModelPropagator.odefun(t,y, eventInitStateLogEntry, tankStates, dryMass, pwrStorageStates, obj.forceModels);
            odeFH = @(tS,yS) ForceModelPropagator.scaledOdeFun(tS,yS, eventInitStateLogEntry, tankStates, dryMass, pwrStorageStates, obj.forceModels, lStar, tStar, vStar, aStar, mStar, mDotStar, cStar, cDotStar);
        end
       
        function odeEventsFH = getOdeEventsFunctionHandle(~, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData)
            tankStates = eventInitStateLogEntry.getAllActiveTankStates();
            pwrStorageStates = eventInitStateLogEntry.getAllActivePwrStorageStates();
            
            [tStar, lStar, vStar, ~, mStar, ~, cStar, ~] = ForceModelPropagator.getScaleFactors(eventInitStateLogEntry);

            odeEventsFH = @(tS,yS) ForceModelPropagator.scaledOdeEvents(tS,yS, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData, lStar, tStar, vStar, mStar, cStar, tankStates, pwrStorageStates);
            % odeEventsFH = @(t,y) AbstractPropagator.odeEvents(t,y, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData);
        end
        
        function odeOutputFH = getOdeOutputFunctionHandle(~, tStartPropTime, maxPropTime, eventInitStateLogEntry, plugins)       
            [tStar, lStar, vStar, ~, mStar, ~, cStar, ~] = ForceModelPropagator.getScaleFactors(eventInitStateLogEntry);

            tankStates = eventInitStateLogEntry.getAllActiveTankStates();
            pwrStorageStates = eventInitStateLogEntry.getAllActivePwrStorageStates();

            % odeOutputFH = @(t,y,flag) ForceModelPropagator.odeOutput(t,y,flag, tStartPropTime, maxPropTime, eventInitStateLogEntry, plugins);
            odeOutputFH = @(tS,yS,flag) ForceModelPropagator.scaledOdeOutput(tS,yS,flag, tStartPropTime, maxPropTime, eventInitStateLogEntry, plugins, lStar, tStar, vStar, mStar, cStar, tankStates, pwrStorageStates);
        end
        
        function [value,isterminal,direction,causes] = callEventsFcn(obj, odeEventsFun, stateLogEntry)
            [t,y, ~] = stateLogEntry.getFirstOrderIntegratorStateRepresentation();
    
            [tStar, lStar, vStar, ~, mStar, ~, cStar, ~] = ForceModelPropagator.getScaleFactors(stateLogEntry);
            tankStates = stateLogEntry.getAllActiveTankStates();
            powerStorageStates = stateLogEntry.getAllActivePwrStorageStates();

            [tS, yS] = ForceModelPropagator.scaleTAndY(t,y, lStar, tStar, vStar, mStar, cStar, tankStates, powerStorageStates);

            [value,isterminal,direction,causes] = odeEventsFun(tS,yS);
        end
        
        function openOptionsDialog(obj)
            fms = obj.forceModels;
            initSelInds = [];
            for(i=1:length(fms)) %#ok<*NO4LP> 
                if(fms(i).canBeDisabled)
                    initSelInds(end+1) = ForceModelsEnum.getIndOfDisablableListboxStrsForModel(fms(i).model); %#ok<AGROW>
                end
            end

            out = AppDesignerGUIOutput();
            listdlgARH_App('ListString',ForceModelsEnum.getListBoxStrsOfDisablableModels(), ...
                        'SelectionMode', 'multiple', ...
                        'ListSize', [300, 300], ...
                        'Name', 'Select Force Models', ...
                        'PromptString', {'Select the Force Models you wish to have enabled during this','event.  Gravity is always enabled.  Disabling Thrust during','periods of coasting may improve performance considerably.'}, ...
                        'InitialValue', initSelInds, ...
                        'out',out);
            Selection = out.output{1};
            ok = out.output{2};

            if(ok == 1)
                m = ForceModelsEnum.getEnumsOfDisablableForceModels();
                obj.forceModels = [ForceModelsEnum.getAllForceModelsThatCannotBeDisabled(), m(Selection)'];
            end
        end
        
        function tf = canProduceThrust(obj)
            tf = any(ismember(obj.forceModels, ForceModelsEnum.Thrust));
        end
    end

    methods(Static, Access=private)
        %%%
        %ODE Function
        %%%
        function dydt = odefun(t,y, eventInitStateLogEntry, tankStates, dryMass, powerStorageStates, fmEnums)
            bodyInfo = eventInitStateLogEntry.centralBody;
            if(isstruct(bodyInfo.celBodyData) || isempty(bodyInfo.celBodyData))
                bodyInfo.celBodyData = eventInitStateLogEntry.celBodyData;
            end
            
            [ut, rVect, vVect, tankStatesMasses, storageSoCs] = AbstractPropagator.decomposeIntegratorTandY(t,y, length(tankStates), length(powerStorageStates));
            altitude = norm(rVect) - bodyInfo.radius;
            
            stageStates = eventInitStateLogEntry.stageStates;
            lvState = eventInitStateLogEntry.lvState;
            t2tConnStates = lvState.t2TConns;

            throttleModel = eventInitStateLogEntry.throttleModel;
            steeringModel = eventInitStateLogEntry.steeringModel;

            holdDownEnabled = eventInitStateLogEntry.isHoldDownEnabled();

            tankMassDotsT2TConns = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, tankStatesMasses, t2tConnStates);

            storageRates = LaunchVehicleStateLogEntry.getStorageChargeRatesDueToSourcesSinks(storageSoCs, powerStorageStates, stageStates, ut, rVect, vVect, bodyInfo, steeringModel);
            
            dydt = zeros(length(y),1);
            if(holdDownEnabled)
                pressure = getPressureAtAltitude(bodyInfo, altitude);
                throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);

                attState = LaunchVehicleAttitudeState();
                attState.dcm = steeringModel.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

                [tankMassDotsEngines,~,~,ecStgDots] = eventInitStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates, attState);

                tankMassDots = tankMassDotsEngines + tankMassDotsT2TConns;
                storageRates = storageRates + ecStgDots;

                %launch clamp is enabled, only motion is circular motion
                %(fixed to body)
                %In this case, we are integrating in the body-fixed frame, 
                %so all rates are effectively zero        
                dydt(1:3) = [0;0;0]; 
                dydt(4:6) = [0;0;0];
                dydt(7:6+length(tankMassDots)) = tankMassDots;
                dydt(6+length(tankMassDots)+1 : 6+length(tankMassDots)+length(storageRates)) = storageRates;
            else
                %launch clamp disabled, propagate like normal
                if(altitude <= 0 && any(fmEnums == ForceModelsEnum.Normal))
                    rswVVect = rotateVectorFromEciToRsw(vVect, rVect, vVect);
                    rswVVect(1) = 0; %kill vertical velocity because we don't want to go throught the surface of the planet
                    vVect = rotateVectorFromRsw2Eci(rswVVect, rVect, vVect);
                end

                aero = eventInitStateLogEntry.aero;
                thirdBodyGravity = eventInitStateLogEntry.thirdBodyGravity;
                srp = eventInitStateLogEntry.srp;

                totalMass = dryMass + sum(tankStatesMasses);

                if(totalMass > 0)
                    [forceSum, tankMassDotsForceModels, ecStgDots] = TotalForceModel.getForce(fmEnums, ut, rVect, vVect, totalMass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity, storageSoCs, powerStorageStates, srp);
                    accelVect = forceSum/totalMass; %F = dp/dt = d(mv)/dt = m*dv/dt + v*dm/dt, but since the thrust force causes us to shed mass, we actually account for the v*dm/dt term there and therefore don't need it!  See: https://en.wikipedia.org/wiki/Variable-mass_system         

                    tankMassDots = tankMassDotsForceModels + tankMassDotsT2TConns;
                    storageRates = storageRates + ecStgDots;
                    
                    dydt(7:6+length(tankMassDots)) = tankMassDots;
                    dydt(6+length(tankMassDots)+1 : 6+length(tankMassDots)+length(storageRates)) = storageRates;
                else
                    accelVect = zeros(3,1);
                    dydt(7:6+length(tankStates)) = zeros(size(tankStates));
                    %don't need to do this really because the dydt is
                    %already zeros
                end

                dydt(1:3) = vVect'; 
                dydt(4:6) = accelVect;
            end
        end

        function yDotS = scaledOdeFun(tS,yS, eventInitStateLogEntry, tankStates, dryMass, powerStorageStates, fmEnums, lStar, tStar, vStar, aStar, mStar, mDotStar, cStar, cDotStar)
            [t, y] = ForceModelPropagator.unscaleTAndY(tS,yS, lStar, tStar, vStar, mStar, cStar, tankStates, powerStorageStates);            
            yDot = ForceModelPropagator.odefun(t,y, eventInitStateLogEntry, tankStates, dryMass, powerStorageStates, fmEnums);

            [mInds, cInds] = ForceModelPropagator.getMandCInds(tankStates, powerStorageStates);
            yDotS = [yDot(1:3) / vStar;
                     yDot(4:6) / aStar;
                     yDot(mInds) / mDotStar;
                     yDot(cInds) / cDotStar];
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

        function status = scaledOdeOutput(tS,yS,flag, intStartTime, maxIntegrationDuration, eventInitStateLogEntry, plugins, lStar, tStar, vStar, mStar, cStar, tankStates, powerStorageStates)
            [t, y] = ForceModelPropagator.unscaleTAndY(tS,yS, lStar, tStar, vStar, mStar, cStar, tankStates, powerStorageStates);
            status = ForceModelPropagator.odeOutput(t,y,flag, intStartTime, maxIntegrationDuration, eventInitStateLogEntry, plugins);
        end

        %%%
        %Scaled ODE Events
        %%%
        function [value,isterminal,direction, causes] = scaledOdeEvents(tS,yS, eventInitStateLogEntry, evtTermCond, termCondDir, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData, lStar, tStar, vStar, mStar, cStar, tankStates, powerStorageStates)
            [t, y] = ForceModelPropagator.unscaleTAndY(tS,yS, lStar, tStar, vStar, mStar, cStar, tankStates, powerStorageStates);
            
            [value,isterminal,direction, causes] = AbstractPropagator.odeEvents(t,y, eventInitStateLogEntry, evtTermCond, termCondDir, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData);
        end

        %%%
        %Scale factors
        %%%
        function [tStar, lStar, vStar, aStar, mStar, mDotStar, cStar, cDotStar] = getScaleFactors(eventInitStateLogEntry)
            %Get initial states
            [t0,y0, ~] = eventInitStateLogEntry.getFirstOrderIntegratorStateRepresentation();

            %Get scale factors
            tankStates = eventInitStateLogEntry.getAllActiveTankStates();
            totalMass = eventInitStateLogEntry.getTotalVehicleMass();
            pwrStorageStates = eventInitStateLogEntry.getAllActivePwrStorageStates();
            [~, rVect0, vVect0, ~, ~] = AbstractPropagator.decomposeIntegratorTandY(t0,y0, length(tankStates), length(pwrStorageStates));
            
            %%% Kinematics
            lStar = norm(rVect0);
            vStar = norm(vVect0);
            tStar = lStar / vStar;
            aStar = vStar / tStar;

            %Mass flow
            mStar = totalMass;
            mDotStar = mStar/tStar;

            %Electrical charge
            pwrStorageStates = eventInitStateLogEntry.getAllActivePwrStorageStates();
            if(not(isempty(pwrStorageStates)))
                cStar = max(1, sum(pwrStorageStates.getStateOfCharge()));
                cDotStar = cStar/tStar;
            else
                cStar = 1;
                cDotStar = 1;
            end
        end

        function [tS, yS] = scaleTAndY(t,y, lStar, tStar, vStar, mStar, cStar, tankStates, powerStorageStates)
            [mInds, cInds] = ForceModelPropagator.getMandCInds(tankStates, powerStorageStates);

            if(isempty(t))
                tS = [];
                yS = [];
            else
                tS = t / tStar;
    
                if(height(y) > 1)
                    yS = [y(1:3) / lStar; ...
                          y(4:6) / vStar; ...
                          y(mInds) / mStar; ...
                          y(cInds) / cStar];

                else
                    yS = [y(1:3) / lStar, ...
                          y(4:6) / vStar, ...
                          y(mInds) / mStar, ...
                          y(cInds) / cStar];
                end
            end
        end

        function [t, y] = unscaleTAndY(tS,yS, lStar, tStar, vStar, mStar, cStar, tankStates, powerStorageStates)
            [mInds, cInds] = ForceModelPropagator.getMandCInds(tankStates, powerStorageStates);

            if(isempty(tS))
                t = [];
                y = [];
            else
                t = tS * tStar;
    
                if(height(yS) > 1)
                    y = [yS(1:3) * lStar; ...
                         yS(4:6) * vStar; ...
                         yS(mInds) * mStar; ...
                         yS(cInds) * cStar];

                else
                    y = [yS(1:3) * lStar, ...
                         yS(4:6) * vStar, ...
                         yS(mInds) * mStar, ...
                         yS(cInds) * cStar];
                end
            end
        end

        function [t,y,te,ye] = unscaleOdeResults(tS, yS, teS, yeS, lStar, tStar, vStar, mStar, cStar, tankStates, powerStorageStates)
            [mInds, cInds] = ForceModelPropagator.getMandCInds(tankStates, powerStorageStates);

            t = tS .* tStar;
            y = [yS(:,1:3)*lStar, yS(:,4:6)*vStar, yS(:,mInds)*mStar, yS(:,cInds)*cStar];

            te = teS .* tStar;
            ye = [yeS(:,1:3)*lStar, yeS(:,4:6)*vStar, yeS(:,mInds)*mStar, yeS(:,cInds)*cStar];
        end

        function [mInds, cInds] = getMandCInds(tankStates, powerStorageStates)
            mInds = 7:6+length(tankStates);
            cInds = 6+length(tankStates)+1 : 6+length(tankStates)+length(powerStorageStates);
        end
    end
end