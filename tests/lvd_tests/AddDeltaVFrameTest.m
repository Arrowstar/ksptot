classdef AddDeltaVFrameTest < KsptotTestCase
    %AddDeltaVFrameTest Delta-v frames and parameterisations of AddDeltaVAction.
    %
    % The Inertial and NTW frames are the ones existing missions use, so they
    % are pinned to the exact helper calls the action has always made.  The
    % new frames (RSW, VNB, body-fixed, user-defined) are checked against
    % basis vectors built from scratch with cross/norm, and the polar
    % (magnitude / angles) parameterisation against its closed form.

    properties(Constant)
        r0 = [7000; 500; 200];   %km
        v0 = [0.1; 7.4; 0.3];    %km/s
        dv = [0.2; -0.03; 0.01]; %km/s
    end

    methods(Test)
        function inertialFrameIsUnchanged(testCase)
            [~, entry] = testCase.buildEntry();

            action = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.Inertial, false);
            newEntry = action.executeAction(entry);

            testCase.verifyEqual(newEntry.velocity, testCase.v0 + testCase.dv, ...
                'Inertial delta-v must be added component-wise, bit for bit.');
        end

        function ntwFrameIsUnchanged(testCase)
            [~, entry] = testCase.buildEntry();

            action = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.OrbitNtw, false);
            newEntry = action.executeAction(entry);

            expected = testCase.v0 + getNTW2ECIdvVect(testCase.dv, testCase.r0, testCase.v0);
            testCase.verifyEqual(newEntry.velocity, expected, ...
                'NTW delta-v must still go through getNTW2ECIdvVect exactly as before.');
        end

        function rswFrameMatchesHandBuiltBasis(testCase)
            [~, entry] = testCase.buildEntry();

            action = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.OrbitRsw, false);
            newEntry = action.executeAction(entry);

            r = testCase.r0; v = testCase.v0; d = testCase.dv;
            R = r/norm(r);
            W = cross(r, v)/norm(cross(r, v));
            S = cross(W, R);
            expected = v + d(1)*R + d(2)*S + d(3)*W;

            testCase.verifyVectorEqual(newEntry.velocity, expected, 1e-12, 'RSW (radial / along-track / cross-track) delta-v');
        end

        function vnbFrameMatchesHandBuiltBasisAndEqualsNtw(testCase)
            [~, entry] = testCase.buildEntry();

            action = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.OrbitVnb, false);
            newEntry = action.executeAction(entry);

            r = testCase.r0; v = testCase.v0; d = testCase.dv;
            V = v/norm(v);
            N = cross(r, v)/norm(cross(r, v));
            B = cross(V, N);
            expected = v + d(1)*V + d(2)*N + d(3)*B;

            testCase.verifyVectorEqual(newEntry.velocity, expected, 1e-12, 'VNB (velocity / normal / binormal) delta-v');

            %KSPTOT's "NTW" ordering (prograde, normal, radial) is the same
            %triad as VNB, so the two frames must agree to rounding.
            [~, entryNtw] = testCase.buildEntry();
            ntwEntry = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.OrbitNtw, false).executeAction(entryNtw);
            testCase.verifyVectorEqual(newEntry.velocity, ntwEntry.velocity, 1e-12, 'VNB and NTW must coincide');
        end

        function bodyFixedFrameRotatesByTheSpinAngle(testCase)
            [~, entry] = testCase.buildEntry();
            bodyInfo = testCase.copyBodyInfo(entry.centralBody);
            bodyInfo.rotperiod = 21600;
            bodyInfo.rotini = 30; %deg
            entry.centralBody = bodyInfo;
            entry.time = 5000;

            action = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.BodyFixed, false);
            newEntry = action.executeAction(entry);

            theta = mod(deg2rad(bodyInfo.rotini) + 2*pi*entry.time/bodyInfo.rotperiod, 2*pi);
            Rz = [cos(theta), -sin(theta), 0;
                  sin(theta),  cos(theta), 0;
                  0,           0,          1];
            expected = testCase.v0 + Rz*testCase.dv;

            testCase.verifyVectorEqual(newEntry.velocity, expected, 1e-12, 'Body-fixed delta-v');

            %With no rotation the body-fixed and inertial frames coincide.
            [~, entry2] = testCase.buildEntry();
            bodyInfo2 = testCase.copyBodyInfo(entry2.centralBody);
            bodyInfo2.rotperiod = Inf;
            bodyInfo2.rotini = 0;
            entry2.centralBody = bodyInfo2;
            newEntry2 = action.executeAction(entry2);
            testCase.verifyVectorEqual(newEntry2.velocity, testCase.v0 + testCase.dv, 1e-12, 'Non-rotating body: body-fixed == inertial');
        end

        function userFrameUsesTheFramesRotation(testCase)
            [~, entry] = testCase.buildEntry();
            bodyInfo = testCase.copyBodyInfo(entry.centralBody);
            bodyInfo.rotperiod = 21600;
            bodyInfo.rotini = 30;
            entry.centralBody = bodyInfo;
            entry.time = 5000;

            %A body-centered inertial frame as the user frame is the identity.
            action = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.UserFrame, false);
            action.userFrame = bodyInfo.getBodyCenteredInertialFrame();
            newEntry = action.executeAction(entry);
            testCase.verifyVectorEqual(newEntry.velocity, testCase.v0 + testCase.dv, 1e-12, 'User frame = body inertial frame');

            %The body-fixed frame as the user frame must agree with the
            %dedicated body-fixed enum.
            [~, entryBf] = testCase.buildEntry();
            entryBf.centralBody = bodyInfo;
            entryBf.time = 5000;
            actionUser = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.UserFrame, false);
            actionUser.userFrame = bodyInfo.getBodyFixedFrame();
            userEntry = actionUser.executeAction(entryBf);

            [~, entryEnum] = testCase.buildEntry();
            entryEnum.centralBody = bodyInfo;
            entryEnum.time = 5000;
            enumEntry = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.BodyFixed, false).executeAction(entryEnum);

            testCase.verifyVectorEqual(userEntry.velocity, enumEntry.velocity, 1e-12, 'User frame = body fixed frame');

            testCase.verifyTrue(actionUser.usesGeometricRefFrame(bodyInfo.getBodyFixedFrame()), ...
                'usesGeometricRefFrame must report the configured user frame.');
            testCase.verifyFalse(actionUser.usesGeometricRefFrame(bodyInfo.getBodyCenteredInertialFrame()));
        end

        function emptyUserFrameFallsBackToInertial(testCase)
            [~, entry] = testCase.buildEntry();

            action = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.UserFrame, false);
            newEntry = action.executeAction(entry);

            testCase.verifyEqual(newEntry.velocity, testCase.v0 + testCase.dv, ...
                'An unconfigured user frame must degrade to the inertial frame rather than error.');
        end

        function polarParameterisationRoundTripsAndPropagatesLikeCartesian(testCase)
            polar = AddDeltaVAction.cartesianToPolar(testCase.dv);
            testCase.verifyEqual(polar(1), norm(testCase.dv), 'AbsTol', 1e-15);
            testCase.verifyVectorEqual(AddDeltaVAction.polarToCartesian(polar), testCase.dv, 1e-15, 'polar -> cartesian round trip');

            %Closed form of the polar components.
            mag = 0.5; ip = deg2rad(40); oop = deg2rad(-15);
            expected = mag*[cos(oop)*cos(ip); cos(oop)*sin(ip); sin(oop)];
            testCase.verifyVectorEqual(AddDeltaVAction.polarToCartesian([mag; ip; oop]), expected, 1e-15, 'polar closed form');

            back = AddDeltaVAction.cartesianToPolar(expected);
            testCase.verifyVectorEqual(back, [mag; ip; oop], 1e-12, 'cartesian -> polar recovers the angles');

            %Zero vector: no angles to speak of.
            testCase.verifyEqual(AddDeltaVAction.cartesianToPolar([0;0;0]), [0;0;0]);

            %Propagating a polar action equals propagating its Cartesian twin
            %in every frame.
            frames = enumeration('DeltaVFrameEnum');
            for(i=1:numel(frames))
                [~, entryC] = testCase.buildEntry();
                cart = AddDeltaVAction(expected, frames(i), false);
                if(frames(i) == DeltaVFrameEnum.UserFrame)
                    cart.userFrame = entryC.centralBody.getBodyFixedFrame();
                end
                vCart = cart.executeAction(entryC).velocity;

                [~, entryP] = testCase.buildEntry();
                pol = AddDeltaVAction([mag; ip; oop], frames(i), false);
                pol.paramType = DeltaVParamTypeEnum.Polar;
                pol.userFrame = cart.userFrame;
                vPol = pol.executeAction(entryP).velocity;

                testCase.verifyVectorEqual(vPol, vCart, 1e-12, sprintf('polar vs cartesian in %s', frames(i).nameStr));
            end
        end

        function namesAndUnitsFollowTheParameterisation(testCase)
            action = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.OrbitRsw, false);
            testCase.verifyEqual(action.getComponentNames(), {'Radial', 'Along-Track', 'Cross-Track'});
            testCase.verifySubstring(action.getName(), 'RSW');

            var = AddDeltaVActionVariable(action);
            var.setUseTfForVariable([true true true]);
            testCase.verifyEqual(var.getVarsDisplayedAsMeters(), [true true true]);
            testCase.verifyEqual(var.getVarsStoredInRad(), [false false false]);
            names = var.getStrNamesOfVars(3, []);
            testCase.verifyEqual(names{2}, 'Event 3 Delta-V (Along-Track)');

            action.paramType = DeltaVParamTypeEnum.Polar;
            action.deltaVVect = [0.5; deg2rad(40); deg2rad(-15)];
            testCase.verifyEqual(action.getComponentNames(), {'Magnitude', 'In-Plane Angle', 'Out-of-Plane Angle'});
            testCase.verifySubstring(action.getName(), '500.000 m/s');
            testCase.verifySubstring(action.getName(), 'In-Plane 40.000 deg');
            testCase.verifyEqual(var.getVarsDisplayedAsMeters(), [true false false]);
            testCase.verifyEqual(var.getVarsStoredInRad(), [false true true]);
            names = var.getStrNamesOfVars(3, []);
            testCase.verifyEqual(names{1}, 'Event 3 Delta-V (Magnitude)');
            testCase.verifyEqual(names{3}, 'Event 3 Delta-V (Out-of-Plane Angle)');

            %Only the active components are named, in order.
            var.setUseTfForVariable([false true true]);
            names = var.getStrNamesOfVars(3, []);
            testCase.verifyEqual(names, {'Event 3 Delta-V (In-Plane Angle)', 'Event 3 Delta-V (Out-of-Plane Angle)'});
        end

        function uploadDataConvertsEveryFrameToNtw(testCase)
            [~, entry] = testCase.buildEntry();
            r = testCase.r0; v = testCase.v0; d = testCase.dv;

            %Existing frames keep their exact formulas.
            inertial = AddDeltaVAction(d, DeltaVFrameEnum.Inertial, false);
            data = inertial.getUploadDvToKspData(entry);
            testCase.verifyEqual(data(3:5), (1000*getNTWdvVect(d, r, v))', 'Inertial upload data');
            testCase.verifyEqual(data(2), entry.time);

            ntw = AddDeltaVAction(d, DeltaVFrameEnum.OrbitNtw, false);
            data = ntw.getUploadDvToKspData(entry);
            testCase.verifyEqual(data(3:5), (1000*d)', 'NTW upload data');

            %A new frame: inertial vector from an independent RSW basis, then
            %expressed in the NTW (T, W, N) triad by hand.
            rsw = AddDeltaVAction(d, DeltaVFrameEnum.OrbitRsw, false);
            data = rsw.getUploadDvToKspData(entry);

            R = r/norm(r); W = cross(r, v)/norm(cross(r, v)); S = cross(W, R);
            dvI = d(1)*R + d(2)*S + d(3)*W;
            T = v/norm(v); N = cross(T, W);
            expectedNtw = 1000*[dot(dvI, T); dot(dvI, W); dot(dvI, N)];

            testCase.verifyVectorEqual(data(3:5), expectedNtw, 1e-9, 'RSW upload data expressed in NTW');
        end

        function defaultsKeepOldObjectsCartesianAndFrameless(testCase)
            action = AddDeltaVAction(testCase.dv, DeltaVFrameEnum.Inertial, false);
            testCase.verifyEqual(action.paramType, DeltaVParamTypeEnum.Cartesian);
            testCase.verifyEmpty(action.userFrame);
            testCase.verifyFalse(action.usesGeometricRefFrame(testCase.kerbinFrame));

            listStrs = DeltaVFrameEnum.getListBoxStr();
            testCase.verifyEqual(numel(listStrs), 6);
            [enum, ~] = DeltaVFrameEnum.getEnumForListboxStr('Orbit Frame (VNB)');
            testCase.verifyEqual(enum, DeltaVFrameEnum.OrbitVnb);
        end
    end

    methods
        function [lvdData, entry] = buildEntry(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            entry.position = testCase.r0;
            entry.velocity = testCase.v0;
        end
    end
end
