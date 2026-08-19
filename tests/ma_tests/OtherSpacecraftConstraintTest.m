classdef OtherSpacecraftConstraintTest < KsptotTestCase
    %OtherSpacecraftConstraintTest Mission Architect "Ref. Spacecraft"
    %constraints and their other-spacecraft -> KSPTOT_BodyInfo conversion.
    %
    % Regression coverage for the crash in "Distance to Ref. Spacecraft"
    % (and the other relative-quantity constraints): the other spacecraft
    % objects in Mission Architect are plain structs, but the astrodynamics
    % chain (getPositOfBodyWRTSun) requires a KSPTOT_BodyInfo, and
    % KSPTOT_BodyInfo spells the parent id property "parentid" (not
    % "parentID" as in the struct).

    methods(Test)

        function convertOtherSCStructToBodyInfoProducesWiredUpBodyInfo(testCase)
            %The conversion must preserve the parent wiring needed by the
            %parent-body chain walk in getPositOfBodyWRTSun.

            otherSC = testCase.makeOtherSC(7000);
            bodyInfo = convertOtherSCStructToBodyInfo(otherSC, testCase.celBodyData);

            testCase.verifyInstanceOf(bodyInfo, 'KSPTOT_BodyInfo', ...
                'converted other SC must be a KSPTOT_BodyInfo');
            testCase.verifyEqual(bodyInfo.parentid, 1, ...
                'parent id must carry over (property is parentid, lowercase d)');
            testCase.verifyEqual(bodyInfo.parent, 'Kerbin', 'parent name must carry over');
            testCase.verifyTrue(isequal(bodyInfo.celBodyData, testCase.celBodyData), ...
                'celestial body data must be attached');
        end

        function convertedBodyInfoPropagatesTheOtherScOrbit(testCase)
            %Keplerian round trip: position and velocity at the epoch must
            %match the orbital elements stored in the struct.

            otherSC = testCase.makeOtherSC(7000);
            bodyInfo = convertOtherSCStructToBodyInfo(otherSC, testCase.celBodyData);

            vCirc = sqrt(testCase.kerbin.gm/7000);
            [rVect, vVect] = getStateAtTime(bodyInfo, 0, testCase.kerbin.gm);

            testCase.verifyVectorEqual(rVect, [0, 7000, 0], 1e-6, 'position at epoch');
            testCase.verifyVectorEqual(vVect, [-vCirc, 0, 0], 1e-6, ...
                'velocity at epoch (prograde at true anomaly 90 deg)');
        end

        function convertedBodyInfoPassesBodyInfoValidation(testCase)
            %Regression: the raw struct previously crashed
            %getPositOfBodyWRTSun() with an arguments-block validation
            %error ("Value must be of type KSPTOT_BodyInfo...").

            otherSC = testCase.makeOtherSC(7000);
            bodyInfo = convertOtherSCStructToBodyInfo(otherSC, testCase.celBodyData);

            rOsc    = getPositOfBodyWRTSun(0, bodyInfo, testCase.celBodyData);
            rKerbin = getPositOfBodyWRTSun(0, testCase.kerbin, testCase.celBodyData);

            testCase.verifyEqual(norm(rOsc - rKerbin), 7000, 'AbsTol', 1e-6, ...
                'converted other SC must sit 7000 km from Kerbin');
        end

        function rawStructThroughReportedPathThrowsValidationError(testCase)
            %Negative control documenting the reported failure mode:
            %"Distance to Ref. Spacecraft" crashed with "Invalid argument
            %at position 2. Value must be of type KSPTOT_BodyInfo or be
            %convertible to KSPTOT_BodyInfo." when the raw other-spacecraft
            %struct reached the astrodynamics chain. The conversion in
            %ma_getDepVarValueUnit must keep that from happening; if this
            %test ever stops throwing, the failure mode has changed.

            otherSC = testCase.makeOtherSC(7000);

            testCase.verifyError(@() ma_GADistToRefSCTask([0, 0, 6800, 0, ...
                -sqrt(testCase.kerbin.gm/6800), 0, 0, 1, 0, 0, 0, 0, 1], ...
                'distToRefSC', otherSC, testCase.celBodyData), ...
                'MATLAB:validation:UnableToConvert', ...
                'raw struct must fail the KSPTOT_BodyInfo validation');
        end

        function distanceConstraintThroughOptimizerPath(testCase)
            %buildConstraints -> ma_genericConstraint -> ma_getDepVarValueUnit.

            [maData, otherSC, stateLogRow] = testCase.makeTestMission();

            const = buildConstraints(maData, testCase.celBodyData, 0, 1000, 'final', '', ...
                                     otherSC, 'Distance to Ref. Spacecraft', true, true);
            [~, ~, value] = const(stateLogRow);

            testCase.verifyEqual(value, 200, 'AbsTol', 1e-6, ...
                'co-planar circular orbits at 6800 and 7000 km are 200 km apart');
        end

        function distanceConstraintAfterPropagationMatchesTwoBodyMotion(testCase)
            %At a later epoch the constraint value must agree with plain
            %two-body propagation of both orbits.

            [maData, otherSC, stateLogRow] = testCase.makeTestMission();

            ut = 600;
            mainScBody = getBodyInfoStructFromOrbit([6800, 0, 0, 0, 0, deg2rad(90), 0]);
            [rMain, vMain] = getStateAtTime(mainScBody, ut, testCase.kerbin.gm);

            stateLogRow(1) = ut;
            stateLogRow(2:4) = rMain(:)';
            stateLogRow(5:7) = vMain(:)';

            const = buildConstraints(maData, testCase.celBodyData, 0, 1000, 'final', '', ...
                                     otherSC, 'Distance to Ref. Spacecraft', true, true);
            [~, ~, value] = const(stateLogRow);

            otherScBody = convertOtherSCStructToBodyInfo(otherSC, testCase.celBodyData);
            [rOsc, ~] = getStateAtTime(otherScBody, ut, testCase.kerbin.gm);

            testCase.verifyEqual(value, norm(rMain - rOsc), 'AbsTol', 1e-6, ...
                'constraint value must match direct two-body propagation');
        end

        function relativeQuantityConstraintsThroughOptimizerPath(testCase)
            %The whole ref-SC relative-quantity family must evaluate
            %without crashing and return physically correct values.

            [maData, otherSC, stateLogRow] = testCase.makeTestMission();

            cases = {'Relative SMA of Ref. Spacecraft',                             200, 1e-6; ...
                     'Relative Eccentricity of Ref. Spacecraft',                      0, 1e-9; ...
                     'Relative Pos. of Ref. Spacecraft (Radial)',                   200, 1e-6; ...
                     'Relative Pos. of Ref. Spacecraft (In-Track)',                   0, 1e-6; ...
                     'Relative Pos. of Ref. Spacecraft (In-Track; Ref. SC-centered)', 0, 1e-6};

            for(i = 1:size(cases, 1)) %#ok<*NO4LP>
                const = buildConstraints(maData, testCase.celBodyData, 0, 1000, 'final', '', ...
                                         otherSC, cases{i, 1}, true, true);
                [~, ~, value] = const(stateLogRow);

                testCase.verifyEqual(value, cases{i, 2}, 'AbsTol', cases{i, 3}, ...
                    sprintf('wrong value for %s', cases{i, 1}));
            end
        end

        function gaPathReturnsValueWithUnits(testCase)
            %Graphical analysis path returns the value with units.

            [maData, otherSC, stateLogRow] = testCase.makeTestMission();

            [value, units] = ma_getDepVarValueUnit(1, stateLogRow, ...
                                    'Distance to Ref. Spacecraft', 0, -1, ...
                                    otherSC.id, -1, maData.spacecraft.propellant.names, ...
                                    maData, testCase.celBodyData, false);

            testCase.verifyEqual(value, 200, 'AbsTol', 1e-6, 'GA distance value');
            testCase.verifyEqual(units, 'km', 'GA distance units');
        end

        function lineOfSightToRefSpacecraftWorks(testCase)
            %The Line of Sight task uses the same funnel and must work too.

            [maData, otherSC, stateLogRow] = testCase.makeTestMission();

            [value, ~] = ma_getDepVarValueUnit(1, stateLogRow, ...
                                    'Line of Sight to Ref. Spacecraft', 0, -1, ...
                                    otherSC.id, -1, maData.spacecraft.propellant.names, ...
                                    maData, testCase.celBodyData, false);

            testCase.verifyEqual(value, 1, 'AbsTol', 1e-9, ...
                'unobstructed co-planar orbits must have line of sight');
        end

        function noOtherSpacecraftSelectedYieldsMinusOne(testCase)
            %With no ref. spacecraft id the task must degrade gracefully
            %rather than crash.

            [maData, ~, stateLogRow] = testCase.makeTestMission();

            [value, ~] = ma_getDepVarValueUnit(1, stateLogRow, ...
                                    'Distance to Ref. Spacecraft', 0, -1, ...
                                    -1, -1, maData.spacecraft.propellant.names, ...
                                    maData, testCase.celBodyData, false);

            testCase.verifyEqual(value, -1, 'missing ref. SC must yield the -1 sentinel');
        end
    end

    methods(Access = protected)

        function otherSC = makeOtherSC(testCase, sma) %#ok<INUSD>
            %makeOtherSC Builds the other-spacecraft struct exactly as
            %ma_OtherSpacecraftGUI does (angles in degrees).

            if(nargin < 2)
                sma = 7000;
            end

            otherSC = struct('id', 0.5, 'name', 'Commsat', 'epoch', 0, ...
                             'sma', sma, 'ecc', 0, 'inc', 0, 'raan', 0, ...
                             'arg', 0, 'mean', 90, 'parent', 'Kerbin', ...
                             'parentID', 1, 'color', 'r');
        end

        function [maData, otherSC, stateLogRow] = makeTestMission(testCase, otherSma)
            %makeTestMission Minimal MA data for the constraint evaluation
            %path. The main spacecraft is on a 6800 km circular prograde
            %orbit at true anomaly 90 deg; the other spacecraft sits on a
            %co-planar circular orbit at otherSma (default 7000 km).

            arguments
                testCase
                otherSma = 7000
            end

            otherSC = testCase.makeOtherSC(otherSma);

            maData.spacecraft.otherSC = {otherSC};
            maData.spacecraft.stations = {};
            maData.spacecraft.propellant.names = {'Liquid Fuel/Ox', 'Monopropellant', 'Xenon'};
            maData.script = {};

            vCirc = sqrt(testCase.kerbin.gm/6800);
            stateLogRow = [0, 0, 6800, 0, -vCirc, 0, 0, 1, 0, 0, 0, 0, 1];
        end
    end
end
