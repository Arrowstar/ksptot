classdef LimitedThrottleModel < AbstractThrottleModel
    %LimitedThrottleModel Wraps any base throttle law with optional dynamic
    %pressure and acceleration limits.
    %
    %   The base model (polynomial, thrust-to-weight, or interpolated table)
    %   produces the commanded throttle.  Two independent limiters may then
    %   reduce it:
    %
    %   Dynamic pressure limit ("max-Q bucket"): the commanded throttle is
    %   capped by a linear ramp in dynamic pressure q.  The ramp is 1 at or
    %   below q = (1 - dynPressRampFrac)*maxDynPress and falls to
    %   dynPressMinThrottle at q >= maxDynPress.  q is computed exactly as
    %   the Graphical Analysis "Dynamic Pressure" quantity (atmosphere
    %   relative velocity, kPa).
    %
    %   Acceleration limit: if the thrust acceleration at the commanded
    %   throttle exceeds maxAccel (m/s^2), the throttle is lowered to the
    %   value that produces maxAccel exactly, using the same thrust
    %   evaluation as T2WThrottleModel.
    %
    %   Both limits default to disabled, in which case the wrapper returns the
    %   base model's throttle unchanged.  Time bookkeeping and optimization
    %   variables are delegated to the base model, so variables defined on
    %   the base law keep working through the wrapper.

    properties
        baseModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();

        enableDynPressLimit(1,1) logical = false;
        maxDynPress(1,1) double = 30;          %kPa
        dynPressRampFrac(1,1) double = 0.10;   %fraction of maxDynPress over which the ramp acts
        dynPressMinThrottle(1,1) double = 0;   %throttle floor reached at maxDynPress

        enableAccelLimit(1,1) logical = false;
        maxAccel(1,1) double = 40;             %m/s^2
    end

    methods
        function throttle = getThrottleAtTime(obj, ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates)
            throttle = obj.baseModel.getThrottleAtTime(ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);

            if(obj.enableDynPressLimit)
                q = LimitedThrottleModel.getDynamicPressure(ut, rVect, vVect, bodyInfo);
                throttle = min(throttle, obj.getDynPressRampThrottle(q));
            end

            if(obj.enableAccelLimit && throttle > 0)
                throttle = obj.applyAccelLimit(throttle, ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);
            end

            if(throttle < 0)
                throttle = 0.0;
            elseif(throttle > 1)
                throttle = 1.0;
            end
        end

        function rampThrottle = getDynPressRampThrottle(obj, q)
            %getDynPressRampThrottle Throttle cap as a function of dynamic
            %pressure q (kPa): 1 below the ramp start, dynPressMinThrottle at
            %or above maxDynPress, linear in between.
            qMax = obj.maxDynPress;
            qStart = (1 - obj.dynPressRampFrac) * qMax;
            floorThrottle = obj.dynPressMinThrottle;

            if(q >= qMax)
                rampThrottle = floorThrottle;
            elseif(q <= qStart || qMax <= qStart)
                rampThrottle = 1;
            else
                rampThrottle = 1 - (1 - floorThrottle) * (q - qStart) / (qMax - qStart);
            end
        end

        function accel = getThrustAccelForThrottle(~, throttle, ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates)
            %getThrustAccelForThrottle Thrust acceleration (m/s^2) the vehicle
            %would see at the given throttle.  Thrust in kN over mass in mT is
            %already m/s^2.
            altitude = norm(rVect) - bodyInfo.radius;
            presskPa = getPressureAtAltitude(bodyInfo, altitude);
            attState = LaunchVehicleAttitudeState();

            [~, totalThrust] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankMasses, stgStates, throttle, lvState, presskPa, ut, rVect, vVect, bodyInfo, [], storageSoCs, powerStorageStates, attState);

            totalMass = dryMass + sum(tankMasses);
            if(totalMass > 0)
                accel = totalThrust / totalMass;
            else
                accel = 0;
            end
        end

        function enum = getThrottleModelTypeEnum(~)
            enum = ThrottleModelEnum.Limited;
        end

        function initThrottleModel(obj, initialStateLogEntry)
            if(obj.throttleContinuity)
                obj.baseModel.throttleContinuity = true;
            end

            obj.baseModel.initThrottleModel(initialStateLogEntry);
        end

        function setInitialThrottleFromState(obj, stateLogEntry, tOffsetDelta)
            obj.baseModel.setInitialThrottleFromState(stateLogEntry, tOffsetDelta);
        end

        function t0 = getT0(obj)
            t0 = obj.baseModel.getT0();
        end

        function setT0(obj, newT0)
            obj.baseModel.setT0(newT0);
        end

        function optVar = getNewOptVar(obj)
            optVar = obj.baseModel.getNewOptVar();
        end

        function optVar = getExistingOptVar(obj)
            optVar = obj.baseModel.getExistingOptVar();
        end

        function setBaseModel(obj, newBaseModel)
            arguments
                obj(1,1) LimitedThrottleModel
                newBaseModel(1,1) AbstractThrottleModel
            end

            if(isa(newBaseModel, 'LimitedThrottleModel'))
                error('A LimitedThrottleModel cannot wrap another LimitedThrottleModel.');
            end

            obj.baseModel = newBaseModel;
        end

        function [addActionTf, throttleModel] = openEditThrottleModelUI(obj, lv, useContinuity)
            output = AppDesignerGUIOutput({false, obj});
            lvd_EditLimitedThrottleModelGUI_App(obj, lv, useContinuity, output);
            addActionTf = output.output{1};
            throttleModel = output.output{2};
        end
    end

    methods(Access=private)
        function obj = LimitedThrottleModel(baseModel)
            if(nargin > 0)
                obj.setBaseModel(baseModel);
            end
        end

        function throttle = applyAccelLimit(obj, throttle, ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates)
            accelFH = @(thr) obj.getThrustAccelForThrottle(thr, ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);

            accelAtCmd = accelFH(throttle);
            if(accelAtCmd <= obj.maxAccel)
                return;
            end

            accelAtZero = accelFH(0.0);
            if(accelAtZero >= obj.maxAccel)
                throttle = 0;
            else
                %Thrust is monotone in throttle so the root is bracketed by
                %[0, commanded throttle].
                throttle = fzero(@(x) accelFH(x) - obj.maxAccel, [0, throttle], optimset('TolX',1E-8));
            end
        end
    end

    methods(Static)
        function model = getDefaultThrottleModel()
            model = LimitedThrottleModel(ThrottlePolyModel.getDefaultThrottleModel());
        end

        function model = getThrottleModelWithBase(baseModel)
            model = LimitedThrottleModel(baseModel);
        end

        function dynP_kPa = getDynamicPressure(ut, rVect, vVect, bodyInfo)
            %getDynamicPressure Dynamic pressure in kPa, matching the Graphical
            %Analysis "Dynamic Pressure" task: atmosphere-relative (body fixed)
            %velocity and zero outside the atmosphere or below the surface.
            rVect = rVect(:);
            vVect = vVect(:);
            altitude = norm(rVect) - bodyInfo.radius;

            if(altitude <= bodyInfo.atmohgt && altitude >= 0)
                [lat, long, ~, ~, ~, ~, ~, vVectECEF] = getLatLongAltFromInertialVect(ut, rVect, bodyInfo, vVect);
                density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long);
            else
                density = 0;
                vVectECEF = [0;0;0];
            end

            vVectEcefMagMS = norm(vVectECEF) * 1000;
            dynP_kPa = density * (vVectEcefMagMS^2) / 2 / 1000;
        end
    end
end
