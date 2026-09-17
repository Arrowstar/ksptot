classdef AddDeltaVAction < AbstractEventAction
    %AddDeltaVAction Applies an impulsive delta-v to the vehicle state.
    %
    %   The delta-v is expressed in one of the DeltaVFrameEnum frames and is
    %   parameterised either as three Cartesian frame components or, in polar
    %   form, as a magnitude and two angles (see DeltaVParamTypeEnum).  The
    %   Inertial and NTW frames are evaluated exactly as they always were so
    %   that existing missions propagate identically.

    properties
        deltaVVect(3,1) double = [0;0;0]; %Cartesian: km/s components.  Polar: [km/s; rad; rad]
        frame(1,1) DeltaVFrameEnum = DeltaVFrameEnum.Inertial;
        useDeltaMass(1,1) logical = false;

        paramType(1,1) DeltaVParamTypeEnum = DeltaVParamTypeEnum.Cartesian;

        %Only used when frame == DeltaVFrameEnum.UserFrame.  Any
        %AbstractReferenceFrame works; the GUI offers the mission's geometric
        %frames (wrapped in UserDefinedGeometricFrame).
        userFrame(1,:) AbstractReferenceFrame = AbstractReferenceFrame.empty(1,0);

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

            dvKmsVect = obj.getDeltaVInertial(newStateLogEntry);

            newStateLogEntry.velocity = newStateLogEntry.velocity + dvKmsVect;

            if(obj.useDeltaMass)
                [tankMDots, totalThrust, tankStates] = AddDeltaVAction.getTankMDotsAndTotalThrustForStateLogEntry(newStateLogEntry);

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

                    if(newStateLogEntry.event.propDir == PropagationDirectionEnum.Forward)
                        massMult = -1; %subtract mass
                    elseif(newStateLogEntry.event.propDir == PropagationDirectionEnum.Backward)
                        massMult = +1; %add mass because we are propagating backwards in time
                    else
                        error('Unknown propagation direction: %s.', newStateLogEntry.event.propDir.name);
                    end

                    for(i=1:length(tankStates))
                        tankStates(i).setTankMass(tankStates(i).getTankMass() + massMult*deltaMassPerTankMT(i));
                    end
                end
            end
        end

        function dvFrameVect = getDeltaVFrameComponents(obj)
            %getDeltaVFrameComponents The three Cartesian components of the
            %delta-v expressed in obj.frame (km/s), regardless of how the
            %action is parameterised.
            switch obj.paramType
                case DeltaVParamTypeEnum.Cartesian
                    dvFrameVect = obj.deltaVVect;

                case DeltaVParamTypeEnum.Polar
                    dvFrameVect = AddDeltaVAction.polarToCartesian(obj.deltaVVect);

                otherwise
                    error('Unknown delta-v parameterization type: %s', obj.paramType.nameStr);
            end
        end

        function dvKmsVect = getDeltaVInertial(obj, stateLogEntry)
            %getDeltaVInertial The delta-v rotated into the central body's
            %inertial frame (the frame the state log stores velocity in).
            dvFrameVect = obj.getDeltaVFrameComponents();

            if(obj.frame == DeltaVFrameEnum.Inertial)
                dvKmsVect = dvFrameVect;

            elseif(obj.frame == DeltaVFrameEnum.OrbitNtw)
                dVVectECI = getNTW2ECIdvVect(dvFrameVect, stateLogEntry.position, stateLogEntry.velocity);
                dvKmsVect = dVVectECI;

            elseif(obj.frame == DeltaVFrameEnum.OrbitRsw)
                dvKmsVect = rotateVectorFromRsw2Eci(dvFrameVect(:), stateLogEntry.position(:), stateLogEntry.velocity(:));

            elseif(obj.frame == DeltaVFrameEnum.OrbitVnb)
                rVect = stateLogEntry.position(:);
                vVect = stateLogEntry.velocity(:);

                vHat = vVect/norm(vVect);
                hVect = crossARH(rVect, vVect);
                nHat = hVect/norm(hVect);
                bHat = crossARH(vHat, nHat);

                dvKmsVect = [vHat, nHat, bHat] * dvFrameVect(:);

            elseif(obj.frame == DeltaVFrameEnum.BodyFixed)
                %A free vector only needs the spin rotation; feeding a zero
                %velocity to the fixed-frame helper keeps its omega x r term
                %out of the result.
                bodyInfo = stateLogEntry.centralBody;
                [dvKmsVect, ~] = getInertialVectFromFixedFrameVect(stateLogEntry.time, dvFrameVect(:), bodyInfo, zeros(3,1));
                dvKmsVect = dvKmsVect(:);

            elseif(obj.frame == DeltaVFrameEnum.UserFrame)
                if(isempty(obj.userFrame))
                    %No frame configured: fall back to the body-centered
                    %inertial frame rather than failing the propagation.
                    dvKmsVect = dvFrameVect;
                else
                    bodyInfo = stateLogEntry.centralBody;
                    time = stateLogEntry.time;
                    vehElemSet = stateLogEntry.getCartesianElementSetRepresentation(false);

                    R_user_to_global = obj.userFrame.getRotMatToInertialAtTime(time, vehElemSet, bodyInfo);
                    R_bodyInertial_to_global = bodyInfo.getBodyCenteredInertialFrame().getRotMatToInertialAtTime(time, vehElemSet, bodyInfo);

                    dvKmsVect = R_bodyInertial_to_global' * (R_user_to_global * dvFrameVect(:));
                end

            else
                error('Unknown reference frame found while executing action AddDeltaVAction.');
            end
        end

        function initAction(obj, initialStateLogEntry)
            %none
        end

        function name = getName(obj)
            frameStr = obj.getFrameNameStr();

            switch obj.paramType
                case DeltaVParamTypeEnum.Cartesian
                    name = sprintf('Add Delta-V ([%0.3f %0.3f %0.3f] m/s %s)', obj.deltaVVect(1)*1000, obj.deltaVVect(2)*1000, obj.deltaVVect(3)*1000, frameStr);

                case DeltaVParamTypeEnum.Polar
                    name = sprintf('Add Delta-V (%0.3f m/s, In-Plane %0.3f deg, Out-of-Plane %0.3f deg %s)', obj.deltaVVect(1)*1000, rad2deg(obj.deltaVVect(2)), rad2deg(obj.deltaVVect(3)), frameStr);

                otherwise
                    error('Unknown delta-v parameterization type: %s', obj.paramType.nameStr);
            end
        end

        function frameStr = getFrameNameStr(obj)
            if(obj.frame == DeltaVFrameEnum.UserFrame && not(isempty(obj.userFrame)))
                frameStr = obj.userFrame.getNameStr();
            else
                frameStr = obj.frame.nameStr;
            end
        end

        function compNames = getComponentNames(obj)
            %getComponentNames Human readable names of the three stored numbers.
            switch obj.paramType
                case DeltaVParamTypeEnum.Cartesian
                    compNames = obj.frame.compNames;

                case DeltaVParamTypeEnum.Polar
                    compNames = AddDeltaVAction.getPolarComponentNames();

                otherwise
                    error('Unknown delta-v parameterization type: %s', obj.paramType.nameStr);
            end
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

        function tf = usesGeometricRefFrame(obj, refFrame)
            %usesGeometricRefFrame True when the user frame is (or wraps) the
            %given geometric reference frame.
            tf = false;

            if(obj.frame == DeltaVFrameEnum.UserFrame && not(isempty(obj.userFrame)))
                if(isa(obj.userFrame, 'UserDefinedGeometricFrame'))
                    tf = obj.userFrame.geometricFrame == refFrame || obj.userFrame.geometricFrame.usesGeometricRefFrame(refFrame);
                elseif(isa(refFrame, 'AbstractReferenceFrame'))
                    tf = obj.userFrame == refFrame;
                end
            end
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

            dvFrameVect = obj.getDeltaVFrameComponents();

            if(obj.frame == DeltaVFrameEnum.Inertial)
                deltaVNTW = 1000*getNTWdvVect(dvFrameVect, rVect(:), vVect(:));

            elseif(obj.frame == DeltaVFrameEnum.OrbitNtw)
                deltaVNTW = 1000*dvFrameVect;

            else
                dvKmsVect = obj.getDeltaVInertial(stateLogEntry);
                deltaVNTW = 1000*getNTWdvVect(dvKmsVect, rVect(:), vVect(:));
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
%             addActionTf = lvd_AddDeltaVActionGUI(action, lv.lvdData);

            output = AppDesignerGUIOutput({false});
            lvd_AddDeltaVActionGUI_App(action, lv.lvdData, output);
            addActionTf = output.output{1};
        end

        function compNames = getPolarComponentNames()
            compNames = {'Magnitude', 'In-Plane Angle', 'Out-of-Plane Angle'};
        end

        function dvCart = polarToCartesian(dvPolar)
            %polarToCartesian [mag; inPlane; outOfPlane] -> frame components.
            mag = dvPolar(1);
            ip = dvPolar(2);
            oop = dvPolar(3);

            dvCart = mag * [cos(oop)*cos(ip); cos(oop)*sin(ip); sin(oop)];
        end

        function dvPolar = cartesianToPolar(dvCart)
            %cartesianToPolar Frame components -> [mag; inPlane; outOfPlane]
            %(angles in radians; a zero vector maps to zero angles).
            mag = norm(dvCart(:));

            if(mag > 0)
                ip = atan2(dvCart(2), dvCart(1));
                oop = asin(max(-1, min(1, dvCart(3)/mag)));
            else
                ip = 0;
                oop = 0;
            end

            dvPolar = [mag; ip; oop];
        end

        function [tankMDots, totalThrust, tankStates] = getTankMDotsAndTotalThrustForStateLogEntry(newStateLogEntry)
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
            for(j=1:length(powerStorageStates)) %#ok<*NO4LP>
                storageSoCs(j) = powerStorageStates(j).getStateOfCharge();
            end

            attState = LaunchVehicleAttitudeState();
            attState.dcm = steeringModel.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

            [tankMDots, totalThrust] = newStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates, attState);
        end
    end
end
