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
                %
                %Unlike ForceModelPropagator -- from which this branch was
                %originally adapted -- y0/yp0 here are the *separate*
                %second order position and velocity (3x1 each), not one
                %concatenated first order state.  So position and velocity
                %must be converted into their own variables and kept
                %separate: rkn1210 asserts numel(y0) == numel(yp0), and it
                %is the horzcat at the bottom of this method that
                %recombines them into the Nx6 state the caller expects.
                %Packing them together here instead produced a 6-element y0
                %against an unconverted 3-element inertial yp0, and an Nx9
                %result on the way back out.
                %
                %yp0 is zeroed rather than set to the converted body-fixed
                %velocity.  This is the second order analogue of what
                %ForceModelPropagator does when held down: it drives both
                %dydt(1:3) and dydt(4:6) to zero, freezing the state in the
                %rotating frame.  Here the only rate the integrator owns is
                %yp, and odefun already returns d2ydt2 = 0, so carrying a
                %nonzero yp0 would let the clamped vehicle coast in a
                %straight line through the body-fixed frame instead of
                %staying put -- its radius would grow without bound.
                bodyInfo = eventInitStateLogEntry.centralBody;
                rVectECEF = getFixedFrameVectFromInertialVect(t0, y0(:), bodyInfo, yp0(:));
                y0 = rVectECEF;
                yp0 = zeros(size(y0));

                [t,y,yp,te,ye,ype,ie] = integrator.integrate(odefun, tspan, y0, yp0, evtsFunc, odeOutputFun);

                [rVectECI, vVectECI] = getInertialVectFromFixedFrameVect(t, y.', bodyInfo, yp.');
                y = rVectECI.';
                yp = vVectECI.';

                if(~isempty(ye))
                    [rVectECIe, vVectECIe] = getInertialVectFromFixedFrameVect(te, ye.', bodyInfo, ype.');
                    ye = rVectECIe.';
                    ype = vVectECIe.';
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
            
            out = AppDesignerGUIOutput();
            listdlgARH_App('ListString',{fmArr.name}, ...
                            'SelectionMode', 'multiple', ...
                            'ListSize', [300, 300], ...
                            'Name', 'Select Force Models', ...
                            'PromptString', {'Select the Force Models you wish to have enabled during this','event.  Gravity is always enabled.  Disabling Thrust during','periods of coasting may improve performance considerably.'}, ...
                            'InitialValue', initSelInds, ...
                            'out',out);
            Selection = out.output{1};
            ok = out.output{2};

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

                %srp is unused by the force models this propagator allows
                %(only Gravity and Gravity3rdBody set allowedForSecondOrder),
                %but TotalForceModel.getForce forwards it unconditionally to
                %every model, so it must still be bound.  Omitting it left
                %the trailing parameter undefined and made "Not enough input
                %arguments" fire on the first derivative evaluation of every
                %non-hold-down propagation.
                srp = eventInitStateLogEntry.srp;

                totalMass = eventInitStateLogEntry.getTotalVehicleMass(); %this isn't the total mass but because we can't

                if(totalMass > 0)
                    [forceSum] = TotalForceModel.getForce(fmEnums, ut, rVect, vVect, totalMass, bodyInfo, [], [], [], [], [], [], dryMass, [], thirdBodyGravity, [], [], srp);
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