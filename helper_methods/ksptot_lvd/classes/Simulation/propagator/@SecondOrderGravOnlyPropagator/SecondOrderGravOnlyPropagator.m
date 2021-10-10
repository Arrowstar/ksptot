classdef SecondOrderGravOnlyPropagator < AbstractPropagator
    %ForceModelPropagator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        forceModels ForceModelsEnum = [ForceModelsEnum.Gravity]; 
    end
    
    properties(Constant)
        propagatorEnum = PropagatorEnum.SecOrdGravOnly;
    end
    
    methods
        function obj = SecondOrderGravOnlyPropagator()

        end
        
        function [t,y,te,ye,ie] = propagate(obj, integrator, tspan, eventInitStateLogEntry, ...
                                            eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData, ...
                                            tStartPropTime, maxPropTime)
                                       
            if(not(isa(integrator, 'AbstractSecondOrderIntegrator')))
                error('The selected integrator must be a second order integrator in order to use this propagator.');
            end

            plugins = eventInitStateLogEntry.lvdData.plugins;         
            
            %Create function handles
            odefun = obj.getOdeFunctionHandle(eventInitStateLogEntry);
            evtsFunc = obj.getOdeEventsFunctionHandle(eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData);
            odeOutputFun = obj.getOdeOutputFunctionHandle(tStartPropTime, maxPropTime, eventInitStateLogEntry, plugins);
            
            %Propagate!
            [t0,y0,yp0] = eventInitStateLogEntry.getSecondOrderIntegratorStateRepresentation();

            if(eventInitStateLogEntry.isHoldDownEnabled())
                %Integrate in the body-fixed frame with zero rates
                %For performance reasons
                bodyInfo = eventInitStateLogEntry.centralBody;
                [rVectECEF, vVectECEF] = getFixedFrameVectFromInertialVect(t0, y0(1:3)', bodyInfo, yp0(1:3)');
                y0 = [rVectECEF', vVectECEF'];

                [t,y,yp,te,ye,ype,ie] = integrator.integrate(odefun, tspan, y0, yp0, evtsFunc, odeOutputFun);

                [rVectECI, vVectECI] = getInertialVectFromFixedFrameVect(t, y(:,1:3)', bodyInfo, yp(:,1:3)');
                y = [rVectECI', vVectECI'];

                if(~isempty(ye))
                    [rVectECIe, vVectECIe] = getInertialVectFromFixedFrameVect(te, ye(:,1:3)', bodyInfo, ype(:,1:3)');
                    ye = [rVectECIe', vVectECIe'];
                end
            else
                [t, y, yp, te, ye, ype, ie] = integrator.integrate(odefun, tspan, y0, yp0, evtsFunc, odeOutputFun);
            end   

            y = horzcat(y,yp);
            ye = horzcat(ye,ype);
        end
        
        function odeFH = getOdeFunctionHandle(obj, eventInitStateLogEntry)
            tankStates = eventInitStateLogEntry.getAllActiveTankStates();
            dryMass = eventInitStateLogEntry.getTotalVehicleDryMass();
            pwrStorageStates = eventInitStateLogEntry.getAllActivePwrStorageStates();
            odeFH = @(t,y) SecondOrderGravOnlyPropagator.odefun(t,y, eventInitStateLogEntry, tankStates, dryMass, pwrStorageStates, obj.forceModels);
        end
        
        function odeEventsFH = getOdeEventsFunctionHandle(~, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData)
            odeEventsFH = @(t,y,yp) AbstractPropagator.odeEvents(t,vertcat(y,yp), eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData);
        end
        
        function odeOutputFH = getOdeOutputFunctionHandle(~, tStartPropTime, maxPropTime, eventInitStateLogEntry, plugins)           
            odeOutputFH = @(t,y,yp,flag) SecondOrderGravOnlyPropagator.odeOutput(t,y,yp,flag, tStartPropTime, maxPropTime, eventInitStateLogEntry, plugins);
        end
        
        function [value,isterminal,direction,causes] = callEventsFcn(obj, odeEventsFun, stateLogEntry)
            [t,y,yp] = stateLogEntry.getSecondOrderIntegratorStateRepresentation();
            [value,isterminal,direction,causes] = odeEventsFun(t,y,yp);
        end
        
        function openOptionsDialog(obj)
            fms = obj.forceModels;
            
            
            fmArr = ForceModelsEnum.getEnumsOfDisablableForceModels();
            fmArr = fmArr([fmArr.allowedForSecondOrder] == true);
            
            [~,initSelInds] = ismember(fms, fmArr);
            initSelInds = initSelInds(initSelInds > 0);
            
            [Selection,ok] = listdlgARH('ListString',{fmArr.name}, ...
                                        'SelectionMode', 'multiple', ...
                                        'ListSize', [300, 300], ...
                                        'Name', 'Select Force Models', ...
                                        'PromptString', {'Select the Force Models you wish to have enabled during this','event.  Gravity is always enabled.  Disabling Thrust during','periods of coasting may improve performance considerably.'}, ...
                                        'InitialValue', initSelInds);

            if(ok == 1)
                obj.forceModels = [ForceModelsEnum.getAllForceModelsThatCannotBeDisabled(), fmArr(Selection)'];
            end
        end
        
        function tf = canProduceThrust(obj)
            tf = false;
        end
    end

    methods(Static)
        function [ut, rVect] = decomposeIntegratorTandY(t,y)
            ut = t;
            rVect = y(1:3);
        end
    end

    methods(Static, Access=private)
        %%%
        %ODE Function
        %%%
        function d2ydt2 = odefun(t,y, eventInitStateLogEntry, tankStates, dryMass, powerStorageStates, fmEnums)
            bodyInfo = eventInitStateLogEntry.centralBody;
            if(isstruct(bodyInfo.celBodyData) || isempty(bodyInfo.celBodyData))
                bodyInfo.celBodyData = eventInitStateLogEntry.celBodyData;
            end

            [ut, rVect] = SecondOrderGravOnlyPropagator.decomposeIntegratorTandY(t,y);
            vVect = [0;0;0]; %placeholder - this ODE function can't be a function of velocity, only position
            altitude = norm(rVect) - bodyInfo.radius;

            holdDownEnabled = eventInitStateLogEntry.isHoldDownEnabled();
            
            d2ydt2 = zeros(length(y),1);
            if(holdDownEnabled)
                %launch clamp is enabled, only motion is circular motion
                %(fixed to body)
                %In this case, we are integrating in the body-fixed frame, 
                %so all rates are effectively zero        
                d2ydt2(1:3) = [0;0;0]; 
            else
                %launch clamp disabled, propagate like normal
                if(altitude <= 0 && any(fmEnums == ForceModelsEnum.Normal))
                    rswVVect = rotateVectorFromEciToRsw(vVect, rVect, vVect);
                    rswVVect(1) = 0; %kill vertical velocity because we don't want to go throught the surface of the planet
                    vVect = rotateVectorFromRsw2Eci(rswVVect, rVect, vVect);
                end

                thirdBodyGravity = eventInitStateLogEntry.thirdBodyGravity;

                totalMass = eventInitStateLogEntry.getTotalVehicleMass(); %this isn't the total mass but because we can't 

                if(totalMass > 0)
                    [forceSum] = TotalForceModel.getForce(fmEnums, ut, rVect, vVect, totalMass, bodyInfo, [], [], [], [], [], [], dryMass, [], thirdBodyGravity, [], []);
                    accelVect = forceSum/totalMass; 
                else
                    accelVect = zeros(3,1);
                end

                d2ydt2(1:3) = accelVect; 
            end
        end
        
        %%%
        %ODE Output
        %%%
        function status = odeOutput(t,y,yp,flag, intStartTime, maxIntegrationDuration, eventInitStateLogEntry, plugins)
            y = vertcat(y,yp);
            plugins.executePluginsAfterTimeStepOdeOutputFcn(t,y,flag, eventInitStateLogEntry);
            
            integrationDuration = toc(intStartTime);

            status = 0;
            if(integrationDuration > maxIntegrationDuration)
                status = 1;
            end
        end
    end
end