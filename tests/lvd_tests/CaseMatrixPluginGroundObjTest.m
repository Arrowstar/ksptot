classdef CaseMatrixPluginGroundObjTest < KsptotTestCase
    %CaseMatrixPluginGroundObjTest Case matrix, plugins, ground objects and a
    %spot check of the graphical analysis task layer.
    %
    % SUBJECT UNDER TEST
    %   helper_methods/ksptot_lvd/classes/GroundObj/
    %       @LaunchVehicleGroundObject, @LaunchVehicleGroundObjectWayPt,
    %       @LaunchVehicleGroundObjectSet
    %   helper_methods/ksptot_lvd/classes/Plugin/
    %       @LvdPlugin, @LvdPluginSet, @LvdPluginExecLocEnum,
    %       vars/@LvdPluginOptimVarWrapper, vars/@LvdPluginOptimVarSet
    %   helper_methods/ksptot_lvd/classes/CaseMatrix/
    %       @LvdCaseMatrix, @LvdCaseMatrixTask, @LvdCaseMatrixTaskParameter,
    %       @LvdCaseMatrixTaskStatusEnum, @LvdCaseMatrixTaskRunStatusEnum,
    %       @LvdCaseMatrixTaskGenerationEvtData
    %   helper_methods/ksptot_lvd/process_data/GraphicalAnalysis/
    %       tasks/lvd_getGraphAnalysisTaskList.m, tasks/lvd_EventNumTask.m,
    %       tasks/lvd_ThrottleTask.m, getLvdGAExcludeList.m
    %
    % INDEPENDENT ORACLE
    %   The geometric expectations for LaunchVehicleGroundObject.getStateAtTime
    %   come from refCentralAngle and refSlerp at the bottom of this file:
    %     * refCentralAngle uses the haversine formula.  Production uses the
    %       Mapping Toolbox distance(...,'radians').  Different formula, same
    %       quantity, so a convention slip in either is detectable.
    %     * refSlerp spells out spherical linear interpolation and takes the
    %       central angle as an EXPLICIT argument.  That is deliberate: it lets
    %       checkGroundObjIntermediatePtUsesCentralAngleDirectly feed the same
    %       oracle both the true central angle and the (central angle)/(body
    %       radius) production used to pass, and assert that production now
    %       matches the former and NOT the latter.
    %   The case matrix combinatorics are checked against refCartesianProduct
    %   (hand-written nested loops, NOT combvec, which is what production uses)
    %   and refNearestRowStandardizedEuclidean (hand-written, NOT knnsearch).
    %
    % REGRESSION GUARDS
    %   Five defects were found while building this file and have since been
    %   fixed.  The cases that found them are still here, inverted into
    %   positive assertions, each carrying a comment naming the file and the
    %   original wrong behaviour so a regression reads as a specific fault
    %   rather than just "some assertion failed":
    %     checkGroundObjMoveWayPtIndexPermutesWayPoints
    %     checkGroundObjNoExtrapolateLoopingInRangeInterpolates
    %     checkGroundObjIntermediatePtUsesCentralAngleDirectly
    %     checkPluginBadWordMatchingIsWholeWordAndCaseInsensitive
    %     checkCaseMatrixCaseFileZeroPadWidthIsUniform
    %
    % SCOPE / SPOT-CHECK POLICY
    %   The brief asks for a representative subset of the graphical analysis
    %   task layer, not all ~28 lvd_*Tasks.m files.  What is covered here is
    %   the LAYER, not the physics: task-list composition (exclusion filtering,
    %   sorting, uniqueness, dynamic per-ground-object names) plus the two
    %   dispatchers whose outputs are independently checkable without redoing
    %   a propagation -- lvd_EventNumTask (must equal event.getEventNum()) and
    %   lvd_ThrottleTask 'throttle' (must equal 100*entry.throttle, i.e. the
    %   percent convention).  The physics-heavy dispatchers are covered
    %   elsewhere or deliberately skipped; see SKIPPED below.
    %
    % SKIPPED (documented)
    %   * LvdCaseMatrix.runAllTasks / LvdCaseMatrix.processTaskOutputs /
    %     LvdCaseMatrixTask.runTask -- runAllTasks errors out immediately
    %     without a parallel pool (LvdCaseMatrix.m:86) and otherwise spawns
    %     parfeval jobs, writes .xlsx and .log files and re-serialises whole
    %     LvdData objects to disk.  Not a unit test.  Everything runAllTasks
    %     consults to decide what to run next (getNextUnRunTask,
    %     keepLoopingOverJobs, areAllJobsDone, areThereUnrunTasks,
    %     getNumOfRunningJobs, getFailedJobsThatCanBeRerun,
    %     areAllPreReqsSatisfied) IS covered, driven by hand.
    %   * LvdCaseMatrixTask.lvdData get/set -- these are load()/save() of a
    %     .mat file at lvdFilePath.  Disk I/O, no logic.
    %   * LvdCaseMatrix.updateFailedTaskWithFitXVector -- needs >= 2 completed
    %     tasks each with a real optimiser x-vector persisted to disk, i.e. the
    %     disk path above.  Its cubicinterp/polyfitn arms are curve-fitting
    %     library calls, not LVD logic.
    %   * LvdPlugin.executePlugin under the AfterTimestep exec location --
    %     reached only from inside an ODE output function; the exec-location
    %     semantics it shares with the other locations are covered by
    %     checkPluginExecLocValueSemantics.
    %   * LvdPluginOptimVarSet.isVarAPluginVar's empty-set branch
    %     (LvdPluginOptimVarSet.m:76, returns TRUE for an empty set, which
    %     reads inverted) -- its single caller, getEventNumberForVar.m:53,
    %     always holds a scalar non-empty set, so the branch is unreachable in
    %     practice and pinning it would pin dead code.  Noted, not pinned.
    %   * lvd_GrdObjTasks azimuth/elevation/range -- the same NED geometry is
    %     already checked against a hand-written oracle in ConstraintTest
    %     (refGroundObjAzElRange).  Not duplicated here.
    %   * lvd_PluginValueTask 'plugin_var_value' (lvd_PluginValueTask.m:17 is
    %     a bare `pluginVarSet` expression with no assignment to datapt -- a
    %     leftover debug statement).  That sub-task string is dispatched to
    %     lvd_PluginVarValueTask instead, so the branch is dead; pinning it
    %     would pin dead code.  Noted, not pinned.

    properties(TestParameter)
        caseName = { ...
            'GroundObjSingleWayPointStateIsStatic', ...
            'GroundObjZeroWayPointsErrors', ...
            'GroundObjDistanceBetweenWayPts', ...
            'GroundObjNextWayPtLoopingAndNot', ...
            'GroundObjInterpolationFixedPointsAndAltitude', ...
            'GroundObjLoopingSegmentSchedule', ...
            'GroundObjPingPongScheduleAndRangeGating', ...
            'GroundObjDegenerateSegmentShortCircuit', ...
            'GroundObjSetManagement', ...
            'GroundObjMoveWayPtIndexPermutesWayPoints', ...
            'GroundObjNoExtrapolateLoopingInRangeInterpolates', ...
            'GroundObjIntermediatePtUsesCentralAngleDirectly', ...
            'PluginUserDataThreadingAndEnableFlag', ...
            'PluginExecLocValueSemantics', ...
            'PluginRuntimeErrorBecomesValidationError', ...
            'PluginDisallowedStringBlocking', ...
            'PluginSetManagementAndOrdering', ...
            'PluginBadWordMatchingIsWholeWordAndCaseInsensitive', ...
            'CaseMatrixParameterComboEnumeration', ...
            'CaseMatrixTaskStateMachine', ...
            'CaseMatrixPrereqsCancelAndUiTable', ...
            'CaseMatrixCaseFileZeroPadWidthIsUniform', ...
            'GraphAnalysisTaskListComposition', ...
            'GraphAnalysisEventNumAndThrottleTasks', ...
        };
    end

    properties(Constant)
        %Kerbin's radius, used all over the ground-object oracles.  Asserted
        %against the real body in checkGroundObjDistanceBetweenWayPts so a
        %change in the stock body data cannot silently invalidate the rest.
        KerbinRadiusKm = 600;

        %Waypoint leg durations for the three-waypoint fixture, in seconds.
        %Deliberately unequal so that a segment-scheduling mistake (using the
        %wrong leg's duration, or dividing by the total instead of the leg)
        %cannot pass by symmetry.
        Leg1 = 100;
        Leg2 = 200;
        Leg3 = 300;
    end

    methods(Test)
        function caseMatrixPluginsAndGroundObjectsBehaveAsSpecified(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Access=private)

        % ----------------------------------------------------------------
        % Ground objects
        % ----------------------------------------------------------------

        function checkGroundObjSingleWayPointStateIsStatic(testCase)
            %A ground object with exactly one waypoint has nowhere to move, so
            %getStateAtTime must return that waypoint's position verbatim with
            %only the time stamp advanced (LaunchVehicleGroundObject.m:122-125).
            grdObj = testCase.makeGroundObject(1);
            wayPt = grdObj.getWayPointAtInd(1);

            for(t = [0, 4242, -1e5, 1e9])
                elemSet = grdObj.getStateAtTime(t);

                testCase.verifyEqual(elemSet.time, t, ...
                    sprintf('Single-waypoint ground object did not stamp the requested time %g onto the returned element set.', t));
                testCase.verifyEqual(elemSet.lat, wayPt.getLatitude(), 'AbsTol', 1e-14, ...
                    sprintf('Single-waypoint ground object moved in latitude at t = %g; with one waypoint there is nothing to interpolate between.', t));
                testCase.verifyEqual(elemSet.long, wayPt.getLongitude(), 'AbsTol', 1e-14, ...
                    sprintf('Single-waypoint ground object moved in longitude at t = %g.', t));
                testCase.verifyEqual(elemSet.alt, wayPt.getAltitude(), 'AbsTol', 1e-14, ...
                    sprintf('Single-waypoint ground object changed altitude at t = %g.', t));
            end

            %The returned set must be a copy, not the waypoint's own element
            %set: getStateAtTime writes .time into it, so handing back the
            %stored handle would corrupt the waypoint.  Production guards this
            %with copyWithoutOptVar() at LaunchVehicleGroundObject.m:123.
            elemSet = grdObj.getStateAtTime(999);
            testCase.verifyNotSameHandle(elemSet, wayPt.getElemSet(), ...
                'getStateAtTime returned the waypoint''s own element set handle; stamping the query time onto it would mutate the waypoint.');
            testCase.verifyEqual(wayPt.getElemSet().time, 0, ...
                'The stored waypoint element set had its time overwritten by a getStateAtTime call.');
        end

        function checkGroundObjZeroWayPointsErrors(testCase)
            %Zero waypoints is not interpolatable; production raises a plain
            %(identifier-free) error at LaunchVehicleGroundObject.m:174.
            grdObj = LaunchVehicleGroundObject('Empty', "", 0, LaunchVehicleGroundObjectWayPt.empty(1,0));

            testCase.verifyEqual(grdObj.getNumWayPts(), 0, ...
                'Fixture broken: the ground object under test was expected to have zero waypoints.');

            caught = MException.empty(1,0);
            try
                grdObj.getStateAtTime(0);
            catch ME
                caught = ME;
            end

            testCase.verifyNotEmpty(caught, ...
                'getStateAtTime on a waypoint-less ground object returned instead of erroring.');
            testCase.verifyEqual(caught.message, 'Need at least one waypoint!', ...
                'getStateAtTime on a waypoint-less ground object raised an unexpected message.');
        end

        function checkGroundObjDistanceBetweenWayPts(testCase)
            %getDistanceBetweenWayPts (LaunchVehicleGroundObject.m:109-119)
            %multiplies distance(...,'radians') -- an ANGLE -- by the body
            %radius to get an arc length in km.  The oracle here is haversine,
            %a different formula for the same central angle.
            grdObj = testCase.makeGroundObject(3);
            wayPts = grdObj.wayPts;

            testCase.verifyEqual(grdObj.centralBodyInfo.radius, testCase.KerbinRadiusKm, 'AbsTol', 1e-9, ...
                'The stock Kerbin radius is no longer 600 km; the hard-coded arc lengths in this file need revisiting.');

            pairs = [1 2; 2 3; 1 3; 2 1];
            for(i = 1:size(pairs,1))
                a = wayPts(pairs(i,1));
                b = wayPts(pairs(i,2));

                actual = grdObj.getDistanceBetweenWayPts(a, b);
                expected = refCentralAngle(a.getLatitude(), a.getLongitude(), ...
                                           b.getLatitude(), b.getLongitude()) * testCase.KerbinRadiusKm;

                testCase.verifyEqual(actual, expected, 'AbsTol', 1e-9, ...
                    sprintf('Great-circle distance between waypoints %u and %u disagrees with the haversine oracle (got %.9f km, expected %.9f km).', ...
                            pairs(i,1), pairs(i,2), actual, expected));
            end

            %Waypoints 1 and 2 are a quarter turn apart on the equator, so the
            %arc must be exactly a quarter of the circumference.  This is an
            %absolute check that does not go through the oracle at all.
            testCase.verifyEqual(grdObj.getDistanceBetweenWayPts(wayPts(1), wayPts(2)), ...
                (pi/2) * testCase.KerbinRadiusKm, 'AbsTol', 1e-9, ...
                'A 90 degree equatorial separation did not come back as a quarter of Kerbin''s circumference.');

            %Distance to itself is zero.
            testCase.verifyEqual(grdObj.getDistanceBetweenWayPts(wayPts(1), wayPts(1)), 0, 'AbsTol', 1e-12, ...
                'The distance from a waypoint to itself was not zero.');
        end

        function checkGroundObjNextWayPtLoopingAndNot(testCase)
            %getNextWaypt (LaunchVehicleGroundObject.m:95-107) wraps to the
            %first waypoint when looping and returns an empty array otherwise.
            grdObj = testCase.makeGroundObject(3);
            wayPts = grdObj.wayPts;

            grdObj.loopWayPts = true;
            testCase.verifySameHandle(grdObj.getNextWaypt(wayPts(1)), wayPts(2), ...
                'getNextWaypt did not advance from waypoint 1 to waypoint 2.');
            testCase.verifySameHandle(grdObj.getNextWaypt(wayPts(2)), wayPts(3), ...
                'getNextWaypt did not advance from waypoint 2 to waypoint 3.');
            testCase.verifySameHandle(grdObj.getNextWaypt(wayPts(3)), wayPts(1), ...
                'getNextWaypt did not wrap from the last waypoint back to the first when loopWayPts is true.');

            grdObj.loopWayPts = false;
            testCase.verifySameHandle(grdObj.getNextWaypt(wayPts(1)), wayPts(2), ...
                'Turning looping off changed the successor of a non-terminal waypoint.');
            testCase.verifyEmpty(grdObj.getNextWaypt(wayPts(3)), ...
                'getNextWaypt returned a successor for the last waypoint even though loopWayPts is false.');
        end

        function checkGroundObjInterpolationFixedPointsAndAltitude(testCase)
            %Position along each leg is spherical linear interpolation at a
            %uniform angular rate, so it is checked against refSlerp on a dense
            %sweep.  Note that f = 0, 0.5 and 1 are exact for ANY central angle
            %(the weights degenerate to a = 1/b = 0, a = b, and a = 0/b = 1),
            %so they alone cannot distinguish a correct interpolator from a
            %chord interpolator -- see
            %checkGroundObjIntermediatePtUsesCentralAngleDirectly, which is
            %where the intermediate fractions were once wrong.
            %Altitude is a separate, plain linear interpolation over the leg
            %(interp1qr at LaunchVehicleGroundObject.m:167).
            grdObj = testCase.makeGroundObject(3);
            grdObj.extrapolateTimes = true;
            grdObj.loopWayPts = true;
            wayPts = grdObj.wayPts;

            legStart = 0;
            for(k = 1:3)
                a = wayPts(k);
                if(k < 3)
                    b = wayPts(k+1);
                else
                    b = wayPts(1);
                end
                legDur = a.timeToNextWayPt;
                delta = refCentralAngle(a.getLatitude(), a.getLongitude(), b.getLatitude(), b.getLongitude());

                for(f = linspace(0, 1, 11))
                    t = legStart + f*legDur;
                    elemSet = grdObj.getStateAtTime(t);

                    [expLat, expLong] = refSlerp(a.getLatitude(), a.getLongitude(), ...
                                                 b.getLatitude(), b.getLongitude(), f, delta);

                    testCase.verifyAngleEqual(elemSet.lat, expLat, 1e-10, ...
                        sprintf('Leg %u latitude at f = %.2f (t = %g s) is not the great-circle value.', k, f, t));
                    testCase.verifyAngleEqual(elemSet.long, expLong, 1e-10, ...
                        sprintf('Leg %u longitude at f = %.2f (t = %g s) is not the great-circle value.', k, f, t));
                end

                %Altitude: dense sweep, plain linear interpolation over the leg.
                for(f = linspace(0, 1, 11))
                    t = legStart + f*legDur;
                    elemSet = grdObj.getStateAtTime(t);
                    expAlt = (1-f)*a.getAltitude() + f*b.getAltitude();

                    testCase.verifyEqual(elemSet.alt, expAlt, 'AbsTol', 1e-10, ...
                        sprintf('Leg %u altitude at f = %.2f (t = %g s) is not the linear interpolation between %g km and %g km.', ...
                                k, f, t, a.getAltitude(), b.getAltitude()));
                end

                legStart = legStart + legDur;
            end
        end

        function checkGroundObjLoopingSegmentSchedule(testCase)
            %The looping schedule (getFractionAndWaypointsIfLooping,
            %LaunchVehicleGroundObject.m:185-209) lays the legs end to end and
            %takes mod(t - initialTime, totalDuration).  With legs of 100, 200
            %and 300 s the cycle is 600 s, so the state at t and at t + 600k
            %must be identical, and negative times must wrap forwards.
            %
            %The waypoints are the checkpoints: at the leg boundaries the
            %interpolator is exact (weights degenerate), so the schedule can
            %be verified independently of the interpolation bug.
            grdObj = testCase.makeGroundObject(3);
            grdObj.extrapolateTimes = true;
            grdObj.loopWayPts = true;
            wayPts = grdObj.wayPts;

            cycle = testCase.Leg1 + testCase.Leg2 + testCase.Leg3;
            testCase.verifyEqual(cycle, 600, 'Fixture broken: the looping cycle length changed.');

            boundaryTimes = [0, testCase.Leg1, testCase.Leg1 + testCase.Leg2];
            for(k = 1:3)
                elemSet = grdObj.getStateAtTime(boundaryTimes(k));
                testCase.verifyAngleEqual(elemSet.lat, wayPts(k).getLatitude(), 1e-12, ...
                    sprintf('At the start of leg %u (t = %g s) the ground object was not sitting on waypoint %u (latitude).', k, boundaryTimes(k), k));
                testCase.verifyAngleEqual(elemSet.long, wayPts(k).getLongitude(), 1e-12, ...
                    sprintf('At the start of leg %u (t = %g s) the ground object was not sitting on waypoint %u (longitude).', k, boundaryTimes(k), k));
            end

            %Periodicity, including a full cycle back and a full cycle forward.
            for(t = [17, 133, 455, 599.5])
                base = grdObj.getStateAtTime(t);
                for(n = [-2 -1 1 3])
                    shifted = grdObj.getStateAtTime(t + n*cycle);
                    testCase.verifyAngleEqual(shifted.lat, base.lat, 1e-12, ...
                        sprintf('The looping ground object is not periodic in latitude: t = %g and t = %g disagree.', t, t + n*cycle));
                    testCase.verifyAngleEqual(shifted.long, base.long, 1e-12, ...
                        sprintf('The looping ground object is not periodic in longitude: t = %g and t = %g disagree.', t, t + n*cycle));
                    testCase.verifyEqual(shifted.alt, base.alt, 'AbsTol', 1e-10, ...
                        sprintf('The looping ground object is not periodic in altitude: t = %g and t = %g disagree.', t, t + n*cycle));
                end
            end

            %initialTime shifts the whole schedule: the phase is measured
            %from initialTime, not from zero (line 194).
            unshifted = grdObj.getStateAtTime(133);
            grdObj.initialTime = 1000;
            shifted = grdObj.getStateAtTime(1000 + 133);
            testCase.verifyAngleEqual(shifted.lat, unshifted.lat, 1e-12, ...
                'initialTime did not shift the looping schedule by exactly the amount it was set to (latitude).');
            testCase.verifyAngleEqual(shifted.long, unshifted.long, 1e-12, ...
                'initialTime did not shift the looping schedule by exactly the amount it was set to (longitude).');
            testCase.verifyEqual(shifted.alt, unshifted.alt, 'AbsTol', 1e-10, ...
                'initialTime did not shift the looping schedule by exactly the amount it was set to (altitude).');
        end

        function checkGroundObjPingPongScheduleAndRangeGating(testCase)
            %With extrapolateTimes = false and loopWayPts = false the object
            %walks out to the last waypoint and back again exactly once, then
            %stops existing:
            %  * the leg durations are the first n-1 times, mirrored
            %    (LaunchVehicleGroundObject.m:212-214), so the cycle is
            %    2*(Leg1 + Leg2) = 600 s here, NOT Leg1+Leg2+Leg3;
            %  * outside [initialTime, initialTime + cycle] getStateAtTime
            %    returns an empty element set (lines 155-159).
            grdObj = testCase.makeGroundObject(3);
            grdObj.extrapolateTimes = false;
            grdObj.loopWayPts = false;
            wayPts = grdObj.wayPts;

            cycle = 2*(testCase.Leg1 + testCase.Leg2);
            testCase.verifyEqual(cycle, 600, 'Fixture broken: the ping-pong cycle length changed.');

            %Out of range in both directions -> empty, not an error and not a
            %clamped value.
            for(t = [-1e-6, -10, cycle + 1e-6, cycle + 1000])
                testCase.verifyEmpty(grdObj.getStateAtTime(t), ...
                    sprintf('A non-extrapolating, non-looping ground object returned a state at t = %g, which is outside its [0, %g] s lifetime.', t, cycle));
            end

            %In range, including both endpoints.
            testCase.verifyNotEmpty(grdObj.getStateAtTime(0), ...
                'A non-extrapolating ground object returned nothing at t = 0, the first instant of its lifetime.');
            testCase.verifyNotEmpty(grdObj.getStateAtTime(cycle), ...
                sprintf('A non-extrapolating ground object returned nothing at t = %g, the last instant of its lifetime.', cycle));

            %The four legs are 1->2 (100 s), 2->3 (200 s), 3->2 (200 s) and
            %2->1 (100 s).  Check the object is on the right waypoint at each
            %boundary; those are the interpolation-exact instants.
            expectedAtBoundary = {0, wayPts(1); ...
                                  testCase.Leg1, wayPts(2); ...
                                  testCase.Leg1 + testCase.Leg2, wayPts(3); ...
                                  testCase.Leg1 + 2*testCase.Leg2, wayPts(2); ...
                                  cycle, wayPts(1)};

            for(i = 1:size(expectedAtBoundary,1))
                t = expectedAtBoundary{i,1};
                wayPt = expectedAtBoundary{i,2};
                elemSet = grdObj.getStateAtTime(t);

                testCase.verifyAngleEqual(elemSet.lat, wayPt.getLatitude(), 1e-12, ...
                    sprintf('The ping-pong ground object was not on the expected waypoint at t = %g s (latitude).', t));
                testCase.verifyAngleEqual(elemSet.long, wayPt.getLongitude(), 1e-12, ...
                    sprintf('The ping-pong ground object was not on the expected waypoint at t = %g s (longitude).', t));
                testCase.verifyEqual(elemSet.alt, wayPt.getAltitude(), 'AbsTol', 1e-10, ...
                    sprintf('The ping-pong ground object was not on the expected waypoint at t = %g s (altitude).', t));
            end

            %The return trip must retrace the outbound trip: t and cycle - t
            %are mirror images.
            for(t = [30, 90, 150, 250])
                out = grdObj.getStateAtTime(t);
                back = grdObj.getStateAtTime(cycle - t);
                testCase.verifyAngleEqual(back.lat, out.lat, 1e-12, ...
                    sprintf('The ping-pong return trip did not retrace the outbound path in latitude at t = %g s.', t));
                testCase.verifyAngleEqual(back.long, out.long, 1e-12, ...
                    sprintf('The ping-pong return trip did not retrace the outbound path in longitude at t = %g s.', t));
            end
        end

        function checkGroundObjDegenerateSegmentShortCircuit(testCase)
            %Two coincident waypoints have no great circle between them, so
            %the interpolator short-circuits (LaunchVehicleGroundObject.m:268)
            %rather than dividing by sin(0).  Altitude must still interpolate.
            frame = testCase.kerbin.getBodyFixedFrame();
            lat = deg2rad(23);
            long = deg2rad(-41);

            wayPts = LaunchVehicleGroundObjectWayPt.empty(1,0);
            wayPts(1) = LaunchVehicleGroundObjectWayPt(GeographicElementSet(0, lat, long, 0, 0,0,0, frame), 100);
            wayPts(2) = LaunchVehicleGroundObjectWayPt(GeographicElementSet(0, lat, long, 8, 0,0,0, frame), 100);

            grdObj = LaunchVehicleGroundObject('Degenerate', "", 0, wayPts);
            grdObj.extrapolateTimes = true;
            grdObj.loopWayPts = true;

            for(f = [0, 0.25, 0.5, 0.75, 1])
                elemSet = grdObj.getStateAtTime(f*100);

                testCase.verifyFalse(any(isnan([elemSet.lat, elemSet.long, elemSet.alt])), ...
                    sprintf('Interpolating between two coincident waypoints produced NaN at f = %.2f; the degenerate-segment short circuit did not fire.', f));
                testCase.verifyAngleEqual(elemSet.lat, lat, 1e-12, ...
                    sprintf('A degenerate (zero length) leg moved the ground object in latitude at f = %.2f.', f));
                testCase.verifyAngleEqual(elemSet.long, long, 1e-12, ...
                    sprintf('A degenerate (zero length) leg moved the ground object in longitude at f = %.2f.', f));
                testCase.verifyEqual(elemSet.alt, f*8, 'AbsTol', 1e-10, ...
                    sprintf('A degenerate leg must still interpolate altitude linearly; at f = %.2f the altitude was wrong.', f));
            end
        end

        function checkGroundObjSetManagement(testCase)
            %LaunchVehicleGroundObjectSet is a plain ordered container with a
            %back-reference: addGroundObj also points the object at its set
            %(LaunchVehicleGroundObjectSet.m:18), which is what makes
            %LaunchVehicleGroundObject.lvdData resolvable.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            set = LaunchVehicleGroundObjectSet(lvdData);

            testCase.verifyEqual(set.getNumGroundObj(), 0, ...
                'A freshly constructed ground object set was not empty.');
            testCase.verifyEmpty(set.getGroundObjAtInd(1), ...
                'Indexing past the end of an empty ground object set did not return an empty array.');

            objs = LaunchVehicleGroundObject.empty(1,0);
            names = {'Alpha', 'Bravo', 'Charlie'};
            for(i = 1:3)
                objs(i) = LaunchVehicleGroundObject.getDefaultObj(testCase.celBodyData);
                objs(i).name = names{i};
                set.addGroundObj(objs(i));
            end

            testCase.verifyEqual(set.getNumGroundObj(), 3, ...
                'The ground object set did not report three members after three adds.');
            testCase.verifyEqual(set.getListboxStr(), names, ...
                'The ground object set listbox strings do not match the names, in order, of the objects that were added.');
            testCase.verifySameHandle(set.getGroundObjAtInd(2), objs(2), ...
                'getGroundObjAtInd(2) did not return the second object added.');
            testCase.verifyEmpty(set.getGroundObjAtInd(0), ...
                'getGroundObjAtInd(0) must return an empty array, not throw or wrap around.');
            testCase.verifyEmpty(set.getGroundObjAtInd(4), ...
                'getGroundObjAtInd past the end must return an empty array.');
            testCase.verifyEqual(set.getIndsForGroundObjs([objs(3) objs(1)]), [1 3], ...
                'getIndsForGroundObjs must report the positions of the requested objects in set order, not in query order.');
            testCase.verifySameHandle(set.getGroundObjsForInds(3), objs(3), ...
                'getGroundObjsForInds did not return the requested object.');

            %The back-reference is what LaunchVehicleGroundObject.lvdData
            %relies on (LaunchVehicleGroundObject.m:48).
            testCase.verifySameHandle(objs(1).groundObjs, set, ...
                'addGroundObj did not set the object''s back-reference to the set that owns it.');
            testCase.verifySameHandle(objs(1).lvdData, lvdData, ...
                'A ground object could not resolve its owning LvdData through the set back-reference.');

            set.removeGroundObj(objs(2));
            testCase.verifyEqual(set.getNumGroundObj(), 2, ...
                'Removing one of three ground objects did not leave two.');
            testCase.verifyEqual(set.getListboxStr(), {'Alpha', 'Charlie'}, ...
                'Removing the middle ground object did not close the gap while preserving the order of the survivors.');

            %Removing something that is not in the set is a no-op, not an error.
            stranger = LaunchVehicleGroundObject.getDefaultObj(testCase.celBodyData);
            set.removeGroundObj(stranger);
            testCase.verifyEqual(set.getNumGroundObj(), 2, ...
                'Removing an object that was never added changed the size of the set.');
        end

        function checkGroundObjMoveWayPtIndexPermutesWayPoints(testCase)
            %--------------------------------------------------------------
            % REGRESSION GUARD (previously-fixed defect)
            %
            % ORIGINAL FAULT
            %   moveWayPtAtIndexDown/Up operated on the wrong property.  They
            %   indexed and assigned obj.loopWayPts -- declared
            %   "loopWayPts(1,1) logical = true" at
            %   helper_methods/ksptot_lvd/classes/GroundObj/
            %       @LaunchVehicleGroundObject/LaunchVehicleGroundObject.m:13,
            %   i.e. a SCALAR flag -- where they meant obj.wayPts.  Down() was
            %   therefore a silent no-op (length(obj.loopWayPts) is always 1,
            %   so "ind < 1" never held) and Up(i >= 2) threw
            %   MATLAB:badsubscript out of the GUI callback.  The lines were
            %   plainly copied from the correct version of the same idiom two
            %   directories away, LvdPluginSet.m:59-69, which
            %   checkPluginSetManagementAndOrdering below exercises.
            %
            %   Both methods now permute obj.wayPts
            %   (LaunchVehicleGroundObject.m:65-75).  A MATLAB:badsubscript
            %   error or an unchanged order below means the scalar-flag
            %   indexing has come back.
            %
            % COVERAGE NOTE
            %   The only production callers are the LVD GUI ground-object
            %   editor buttons, which are out of scope for this suite, so this
            %   is the only coverage these two methods have.
            %--------------------------------------------------------------
            grdObj = testCase.makeGroundObject(3);
            original = grdObj.wayPts;
            grdObj.loopWayPts = true;

            %Down(1): [1 2 3] -> [2 1 3].
            grdObj.moveWayPtAtIndexDown(1);
            testCase.verifyEqual(grdObj.wayPts, original([2 1 3]), ...
                'moveWayPtAtIndexDown(1) must swap the first two waypoints; a no-op here means it is indexing the scalar loopWayPts flag again.');

            %Down(2) on the new order: [2 1 3] -> [2 3 1].
            grdObj.moveWayPtAtIndexDown(2);
            testCase.verifyEqual(grdObj.wayPts, original([2 3 1]), ...
                'moveWayPtAtIndexDown(2) must swap the second and third waypoints.');

            %Up(3): [2 3 1] -> [2 1 3].
            grdObj.moveWayPtAtIndexUp(3);
            testCase.verifyEqual(grdObj.wayPts, original([2 1 3]), ...
                'moveWayPtAtIndexUp(3) must swap the last two waypoints; a MATLAB:badsubscript error here means it is indexing the scalar loopWayPts flag again.');

            %Up(2): back to [1 2 3].
            grdObj.moveWayPtAtIndexUp(2);
            testCase.verifyEqual(grdObj.wayPts, original, ...
                'moveWayPtAtIndexUp(2) must restore the original order after the three swaps above.');

            %The ends of the list are no-ops, not errors and not wrap-arounds.
            grdObj.moveWayPtAtIndexUp(1);
            testCase.verifyEqual(grdObj.wayPts, original, ...
                'moveWayPtAtIndexUp(1) must be a no-op at the top of the list.');
            grdObj.moveWayPtAtIndexDown(3);
            testCase.verifyEqual(grdObj.wayPts, original, ...
                'moveWayPtAtIndexDown(3) must be a no-op at the bottom of the list.');

            %The loop flag is a separate property and must never be touched by
            %a reordering call -- that confusion was the original fault.
            testCase.verifyTrue(grdObj.loopWayPts, ...
                'Reordering waypoints altered the loopWayPts flag; the two properties have been conflated again.');
        end

        function checkGroundObjNoExtrapolateLoopingInRangeInterpolates(testCase)
            %--------------------------------------------------------------
            % REGRESSION GUARD (previously-fixed defect)
            %
            % ORIGINAL FAULT
            %   The extrapolateTimes = false / loopWayPts = true dispatch arm
            %   called a misspelled private method.  At
            %   helper_methods/ksptot_lvd/classes/GroundObj/
            %       @LaunchVehicleGroundObject/LaunchVehicleGroundObject.m:144
            %       obj.getFractionAndWaypointIfLooping(time)
            %   where the method declared at line 185 is
            %       getFractionAndWaypointsIfLooping    (Waypoint*s*)
            %   The other three arms (lines 128, 131 and 146) spelled their
            %   callees correctly, so exactly one of the four had the typo and
            %   this flag combination was completely unusable: every in-range
            %   query threw MATLAB:noSuchMethodOrField out of lvd_GrdObjTasks,
            %   the GroundObjAz/El/Range constraints and the ground-track plot.
            %
            %   Line 144 now spells the method correctly.  A
            %   MATLAB:noSuchMethodOrField below means the typo is back.
            %
            % WHAT THIS ARM MUST DO
            %   Inside [initialTime, initialTime + totalWayPtDuration] it must
            %   agree exactly with the extrapolating/looping arm -- the only
            %   difference between the two is that this one refuses to answer
            %   outside the first cycle.  Both halves are checked so a partial
            %   regression is still caught.
            %--------------------------------------------------------------
            grdObj = testCase.makeGroundObject(3);
            grdObj.extrapolateTimes = false;
            grdObj.loopWayPts = true;
            wayPts = grdObj.wayPts;

            cycle = testCase.Leg1 + testCase.Leg2 + testCase.Leg3;

            %The out-of-range gate (LaunchVehicleGroundObject.m:138-142) is
            %upstream of the interpolation and must still return empty.
            for(t = [-1e-6, -500, cycle + 1e-6, cycle + 500])
                testCase.verifyEmpty(grdObj.getStateAtTime(t), ...
                    sprintf('The out-of-range gate at LaunchVehicleGroundObject.m:138-142 did not return an empty element set at t = %g.', t));
            end

            %In range: the leg boundaries are the interpolation-exact instants,
            %so the object must be sitting on the corresponding waypoint.
            boundaryTimes = [0, testCase.Leg1, testCase.Leg1 + testCase.Leg2];
            for(k = 1:3)
                elemSet = grdObj.getStateAtTime(boundaryTimes(k));
                testCase.verifyNotEmpty(elemSet, ...
                    sprintf('A non-extrapolating, looping ground object returned nothing at t = %g s, which is inside its first cycle.', boundaryTimes(k)));
                testCase.verifyAngleEqual(elemSet.lat, wayPts(k).getLatitude(), 1e-12, ...
                    sprintf('At the start of leg %u (t = %g s) the ground object was not sitting on waypoint %u (latitude).', k, boundaryTimes(k), k));
                testCase.verifyAngleEqual(elemSet.long, wayPts(k).getLongitude(), 1e-12, ...
                    sprintf('At the start of leg %u (t = %g s) the ground object was not sitting on waypoint %u (longitude).', k, boundaryTimes(k), k));
            end

            %In range, this arm must agree with the extrapolating/looping arm
            %exactly: they share getFractionAndWaypointsIfLooping, so any
            %disagreement means one of them is calling something else.
            for(t = [0, 50, 133, 300, 455, cycle])
                gated = grdObj.getStateAtTime(t);
                grdObj.extrapolateTimes = true;
                ungated = grdObj.getStateAtTime(t);
                grdObj.extrapolateTimes = false;

                testCase.verifyNotEmpty(gated, ...
                    sprintf('A non-extrapolating, looping ground object returned nothing at t = %g s, which is inside its first cycle.', t));
                testCase.verifyAngleEqual(gated.lat, ungated.lat, 1e-12, ...
                    sprintf('Inside the first cycle (t = %g s) the non-extrapolating looping arm disagreed with the extrapolating one in latitude.', t));
                testCase.verifyAngleEqual(gated.long, ungated.long, 1e-12, ...
                    sprintf('Inside the first cycle (t = %g s) the non-extrapolating looping arm disagreed with the extrapolating one in longitude.', t));
                testCase.verifyEqual(gated.alt, ungated.alt, 'AbsTol', 1e-10, ...
                    sprintf('Inside the first cycle (t = %g s) the non-extrapolating looping arm disagreed with the extrapolating one in altitude.', t));
            end
        end

        function checkGroundObjIntermediatePtUsesCentralAngleDirectly(testCase)
            %--------------------------------------------------------------
            % REGRESSION GUARD (previously-fixed defect)
            %
            % ORIGINAL FAULT
            %   getIntermediatePt divided the central angle by the body radius
            %   before slerping.
            %   helper_methods/ksptot_lvd/classes/GroundObj/
            %       @LaunchVehicleGroundObject/LaunchVehicleGroundObject.m
            %       d     = distance(lat1,long1, lat2,long2, 'radians');
            %       delta = d/bodyRadius;                 % <- the fault
            %   distance(...,'radians') already returns an ANGLE, which the
            %   same file proves at lines 117-118 where getDistanceBetweenWayPts
            %   MULTIPLIES that call's result by bodyRadius to get kilometres.
            %   For Kerbin delta came out 600x too small, so sin(x) ~ x, the
            %   slerp weights collapsed to (1-f) and f, and production did a
            %   CHORD interpolation of the two unit vectors renormalised
            %   through atan2.  The track stayed on the right great circle and
            %   f = 0, 0.5 and 1 were still exact, but everywhere else the
            %   object was at the wrong place along that circle -- crawling
            %   near the endpoints and sprinting through the middle.  On a
            %   90 degree equatorial leg, f = 0.25 gave 18.4350 E instead of
            %   22.5 E: 4.065 degrees, about 42.6 km of ground track.
            %
            %   Line 272 now reads "delta = distance(...,'radians');" with no
            %   division, so the leg is traversed at a uniform angular rate.
            %
            % WHY BOTH DELTAS ARE FED TO THE ORACLE
            %   refSlerp takes the central angle as an explicit argument, so
            %   the same oracle produces the correct track and the old
            %   divided-by-radius track.  Asserting agreement with the first
            %   AND disagreement with the second is what makes this a guard
            %   rather than a restatement of whatever production does.
            %
            % COVERAGE NOTE
            %   getIntermediatePt is a local function with a single caller,
            %   LaunchVehicleGroundObject.m:164, so every consumer of
            %   getStateAtTime inherited the fault: lvd_GrdObjTasks,
            %   GroundObjAz/El/RangeConstraint and ground-track plotting.
            %   Constraints evaluated at a leg midpoint or endpoint were
            %   unaffected, which is why it stayed hidden for so long.
            %--------------------------------------------------------------
            grdObj = testCase.makeGroundObject(3);
            grdObj.extrapolateTimes = true;
            grdObj.loopWayPts = true;
            wayPts = grdObj.wayPts;

            %Leg 1: (0 N, 0 E) -> (0 N, 90 E) over Leg1 seconds.
            a = wayPts(1);
            b = wayPts(2);
            trueDelta = refCentralAngle(a.getLatitude(), a.getLongitude(), b.getLatitude(), b.getLongitude());
            dividedDelta = trueDelta / testCase.KerbinRadiusKm;

            testCase.verifyEqual(trueDelta, pi/2, 'AbsTol', 1e-12, ...
                'Fixture broken: the first leg is no longer a 90 degree equatorial arc.');

            for(f = [0.1, 0.25, 0.75, 0.9])
                elemSet = grdObj.getStateAtTime(f * testCase.Leg1);

                [trueLat, trueLong] = refSlerp(a.getLatitude(), a.getLongitude(), ...
                                               b.getLatitude(), b.getLongitude(), f, trueDelta);
                [divLat,  divLong]  = refSlerp(a.getLatitude(), a.getLongitude(), ...
                                               b.getLatitude(), b.getLongitude(), f, dividedDelta);

                %(1) Production matches the true great-circle slerp.
                testCase.verifyAngleEqual(elemSet.long, trueLong, 1e-10, ...
                    sprintf('At f = %.2f the longitude is not the uniform-angular-rate great-circle value; check whether the central angle is being divided by the body radius again.', f));
                testCase.verifyAngleEqual(elemSet.lat, trueLat, 1e-10, ...
                    sprintf('At f = %.2f the latitude is not the uniform-angular-rate great-circle value.', f));

                %(2) ...and is NOT the old divided-by-radius chord track, which
                %at these fractions differs by more than a degree.
                divErrDeg = rad2deg(abs(angleNegPiToPi(trueLong - divLong)));
                testCase.verifyGreaterThan(divErrDeg, 1.0, ...
                    sprintf('Test assumption broken: at f = %.2f the divided-by-radius track is within 1 degree of the truth (%.4f deg), so this f cannot discriminate between them.', f, divErrDeg));

                longErrDeg = rad2deg(abs(angleNegPiToPi(elemSet.long - divLong)));
                testCase.verifyGreaterThan(longErrDeg, 1.0, ...
                    sprintf('At f = %.2f production reproduced the old delta = d/bodyRadius chord track (within %.4f deg of it).', f, longErrDeg));
            end

            %The headline numbers from the original defect report, checked so
            %the comment above cannot rot: a quarter of the way along a 90
            %degree leg is 22.5 E, not the 18.4350 E the chord track gave.
            elemSet = grdObj.getStateAtTime(0.25 * testCase.Leg1);
            testCase.verifyEqual(rad2deg(elemSet.long), 22.5, 'AbsTol', 1e-9, ...
                'A quarter of the way along a 90 degree equatorial leg must be 22.5 deg east; 18.4350 deg is the old atan2(0.25,0.75) chord-interpolation value.');

            %Uniform angular rate is the whole point of slerp: equal time steps
            %along an equatorial leg must cover equal longitude steps.
            fracs = linspace(0, 1, 11);
            longs = zeros(size(fracs));
            for(i = 1:numel(fracs))
                elemSet = grdObj.getStateAtTime(fracs(i) * testCase.Leg1);
                longs(i) = elemSet.long;

                testCase.verifyEqual(elemSet.lat, 0, 'AbsTol', 1e-12, ...
                    sprintf('At f = %.2f the interpolated point left the equator, so it is no longer on the great circle joining the two waypoints.', fracs(i)));
            end
            steps = diff(longs);
            testCase.verifyEqual(steps, repmat((pi/2)/10, 1, 10), 'AbsTol', 1e-10, ...
                'Equal time steps along a 90 degree equatorial leg did not produce equal longitude steps; the ground object is not moving at a uniform angular rate.');
        end

        % ----------------------------------------------------------------
        % Plugins
        % ----------------------------------------------------------------

        function checkPluginUserDataThreadingAndEnableFlag(testCase)
            %LvdPluginSet threads a single userData value through every plugin
            %invocation: the return of one call becomes the argument of the
            %next (LvdPluginSet.m:89).  That is the only state a plugin has,
            %so it has to survive across calls and be resettable.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            pluginSet = lvdData.plugins;

            plugin = LvdPlugin();
            plugin.pluginName = 'Counter';
            plugin.execBeforePropTF = true;
            plugin.pluginCode = "if(isempty(userData)); userData = 0; end; userData = userData + 1;";
            pluginSet.addPlugin(plugin);

            testCase.verifyEqual(pluginSet.getNumPlugins(), 1, ...
                'The plugin set did not report one plugin after one add.');

            pluginSet.initializePlugins();
            testCase.verifyEmpty(pluginSet.userData, ...
                'initializePlugins did not clear userData.');

            for(n = 1:4)
                pluginSet.executePluginsBeforeProp([]);
                testCase.verifyEqual(pluginSet.userData, n, ...
                    sprintf('userData was not threaded from one plugin invocation to the next: after %u BeforeProp executions it should be %u.', n, n));
            end

            %The exec-location switches gate which hook fires.  Only
            %execBeforePropTF is set, so the other four must not run.
            pluginSet.executePluginsBeforeEvent([], LaunchVehicleEvent.empty(0,1));
            pluginSet.executePluginsAfterEvent([], LaunchVehicleEvent.empty(0,1));
            pluginSet.executePluginsAfterProp([]);
            pluginSet.executePluginsAfterTimeStepOdeOutputFcn([], [], [], []);
            testCase.verifyEqual(pluginSet.userData, 4, ...
                'A plugin with only execBeforePropTF set was executed by one of the other four hooks.');

            plugin.execAfterPropTF = true;
            pluginSet.executePluginsAfterProp([]);
            testCase.verifyEqual(pluginSet.userData, 5, ...
                'Setting execAfterPropTF did not make the AfterProp hook run the plugin.');

            %enablePlugins is the master switch (LvdPluginSet.m:86).
            pluginSet.enablePlugins = false;
            pluginSet.executePluginsBeforeProp([]);
            pluginSet.executePluginsAfterProp([]);
            testCase.verifyEqual(pluginSet.userData, 5, ...
                'Plugins still executed after enablePlugins was set to false.');

            pluginSet.enablePlugins = true;
            pluginSet.executePluginsBeforeProp([]);
            testCase.verifyEqual(pluginSet.userData, 6, ...
                'Plugins did not resume executing after enablePlugins was set back to true.');

            testCase.verifyEmpty(lvdData.validation.outputs, ...
                'A well-behaved plugin produced validation errors.');
        end

        function checkPluginExecLocValueSemantics(testCase)
            %executePlugin has two contracts depending on where it is called
            %from (LvdPlugin.m:65-67):
            %  * Constraint and GraphAnalysis: the plugin must assign a
            %    variable literally named "value", and THAT is what comes back.
            %  * every other location: whatever the plugin left in "userData"
            %    comes back, and "value" is ignored.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            plugin = LvdPlugin();
            plugin.pluginName = 'Valuer';
            plugin.pluginCode = "value = 7.5; userData = 'from-userdata';";

            valueLocs = [LvdPluginExecLocEnum.Constraint, LvdPluginExecLocEnum.GraphAnalysis];
            for(i = 1:numel(valueLocs))
                out = testCase.runPlugin(plugin, lvdData, valueLocs(i), 'incoming');
                testCase.verifyEqual(out, 7.5, ...
                    sprintf('At exec location "%s" the plugin''s "value" variable should be returned, not its userData.', valueLocs(i).name));
            end

            userDataLocs = [LvdPluginExecLocEnum.BeforeProp, LvdPluginExecLocEnum.BeforeEvent, ...
                            LvdPluginExecLocEnum.AfterEvent, LvdPluginExecLocEnum.AfterProp, ...
                            LvdPluginExecLocEnum.AfterTimestep];
            for(i = 1:numel(userDataLocs))
                out = testCase.runPlugin(plugin, lvdData, userDataLocs(i), 'incoming');
                testCase.verifyEqual(out, 'from-userdata', ...
                    sprintf('At exec location "%s" the plugin''s userData should be returned, not its "value" variable.', userDataLocs(i).name));
            end

            %A plugin that never assigns userData leaves the incoming value
            %untouched -- the caller's accumulator must not be destroyed.
            plugin.pluginCode = "value = 1;";
            out = testCase.runPlugin(plugin, lvdData, LvdPluginExecLocEnum.AfterProp, 'incoming');
            testCase.verifyEqual(out, 'incoming', ...
                'A plugin that does not assign userData must leave the incoming userData unchanged.');

            testCase.verifyEmpty(lvdData.validation.outputs, ...
                'Well-formed plugin code produced validation errors.');

            %A Constraint-location plugin that forgets to assign "value" is a
            %user error, reported as a validation error rather than thrown.
            plugin.pluginCode = "userData = 3;";
            nBefore = numel(lvdData.validation.outputs);
            out = testCase.runPlugin(plugin, lvdData, LvdPluginExecLocEnum.Constraint, 'incoming');
            testCase.verifyEqual(numel(lvdData.validation.outputs), nBefore + 1, ...
                'A Constraint-location plugin that never assigns "value" should log exactly one validation error.');
            testCase.verifySubstring(lvdData.validation.outputs(end).str, 'Unrecognized function or variable ''value''', ...
                'The validation error for a missing "value" assignment did not name the missing variable.');
            testCase.verifyEqual(out, 3, ...
                'When the "value" lookup fails, the userData the plugin did set should still be returned rather than lost.');
        end

        function checkPluginRuntimeErrorBecomesValidationError(testCase)
            %A plugin is user-supplied code run under eval.  An error inside it
            %must never escape into the propagator; LvdPlugin.m:68-72 catches
            %it and files a LaunchVehicleDataValidationError instead.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            plugin = LvdPlugin();
            plugin.pluginName = 'Exploder';
            plugin.pluginCode = "error('MyPkg:boom','kaboom %d', 42);";

            out = testCase.runPlugin(plugin, lvdData, LvdPluginExecLocEnum.AfterEvent, 'preserved');

            testCase.verifyEqual(numel(lvdData.validation.outputs), 1, ...
                'A plugin that threw did not produce exactly one validation output.');
            testCase.verifyClass(lvdData.validation.outputs(1), 'LaunchVehicleDataValidationError', ...
                'A plugin runtime failure should be recorded as an error, not a warning.');

            str = lvdData.validation.outputs(1).str;
            testCase.verifySubstring(str, 'Exploder', ...
                'The plugin failure message does not name the plugin that failed.');
            testCase.verifySubstring(str, LvdPluginExecLocEnum.AfterEvent.name, ...
                'The plugin failure message does not name the exec location it failed at.');
            testCase.verifySubstring(str, 'kaboom 42', ...
                'The plugin failure message does not carry the underlying MException message.');

            testCase.verifyEqual(out, 'preserved', ...
                'A plugin that threw destroyed the caller''s userData; it should be passed through untouched.');

            %Syntactically invalid code takes the same path.
            plugin.pluginCode = "this is not matlab(((";
            testCase.runPlugin(plugin, lvdData, LvdPluginExecLocEnum.BeforeProp, []);
            testCase.verifyEqual(numel(lvdData.validation.outputs), 2, ...
                'Syntactically invalid plugin code did not produce a second validation error.');
        end

        function checkPluginDisallowedStringBlocking(testCase)
            %LvdPlugin refuses to eval code containing any of a fixed list of
            %dangerous strings (LvdPlugin.m:25-28, checked at line 37).  Both
            %polarities matter: blocked code must not run AND must be
            %reported, and innocuous code must run.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            badWords = LvdPlugin.getDisallowedStrings();

            testCase.verifyNotEmpty(badWords, ...
                'The disallowed-string list is empty, so plugin sandboxing is doing nothing.');
            for(w = {'system', 'dos', 'unix', 'delete', 'rmdir', 'perl'})
                testCase.verifyTrue(any(strcmp(badWords, w{1})), ...
                    sprintf('"%s" is missing from the plugin disallowed-string list.', w{1}));
            end

            plugin = LvdPlugin();
            plugin.pluginName = 'Naughty';

            %Blocked: the code must NOT run (userData passes straight through)
            %and exactly one validation error must name the offending string.
            for(i = 1:numel(badWords))
                word = badWords{i};
                plugin.pluginCode = string(sprintf('userData = 999; x = %s;', word));

                lvdData.validation.outputs = LaunchVehicleDataValidationError.empty(1,0);
                out = testCase.runPlugin(plugin, lvdData, LvdPluginExecLocEnum.BeforeProp, 'untouched');

                testCase.verifyEqual(out, 'untouched', ...
                    sprintf('Plugin code containing the disallowed string "%s" was executed anyway (userData changed).', word));
                testCase.verifyEqual(numel(lvdData.validation.outputs), 1, ...
                    sprintf('Blocking the disallowed string "%s" did not produce exactly one validation error.', word));
                testCase.verifySubstring(lvdData.validation.outputs(1).str, 'not allowed in LVD plugin code', ...
                    sprintf('The validation error for the disallowed string "%s" is not the sandbox message.', word));
                testCase.verifySubstring(lvdData.validation.outputs(1).str, sprintf('"%s"', word), ...
                    sprintf('The validation error did not quote the disallowed string "%s" that was actually found.', word));
            end

            %Allowed: ordinary arithmetic runs and reports nothing.  Every
            %identifier here avoids even embedding a disallowed word;
            %checkPluginBadWordMatchingIsWholeWordAndCaseInsensitive below is
            %what covers identifiers that do embed one.
            lvdData.validation.outputs = LaunchVehicleDataValidationError.empty(1,0);
            plugin.pluginCode = "q = 3; r = q^2 + sqrt(16); userData = r;";
            out = testCase.runPlugin(plugin, lvdData, LvdPluginExecLocEnum.BeforeProp, []);
            testCase.verifyEqual(out, 13, ...
                'Innocuous plugin code did not run: 3^2 + sqrt(16) should be 13.');
            testCase.verifyEmpty(lvdData.validation.outputs, ...
                'Innocuous plugin code was flagged by the sandbox.');
        end

        function checkPluginSetManagementAndOrdering(testCase)
            %LvdPluginSet ordering.  This is also the CONTROL for
            %checkBugGroundObjMoveWayPtIndexPermutesLoopFlag: the move
            %methods here (LvdPluginSet.m:59-69) are the correct version of
            %the idiom that LaunchVehicleGroundObject.m:65-75 got wrong.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            set = LvdPluginSet(lvdData);

            testCase.verifyEqual(set.getNumPlugins(), 0, ...
                'A freshly constructed plugin set was not empty.');

            plugins = LvdPlugin.empty(1,0);
            names = {'A', 'B', 'C'};
            for(i = 1:3)
                plugins(i) = LvdPlugin();
                plugins(i).pluginName = names{i};
                set.addPlugin(plugins(i));
            end

            testCase.verifyEqual(set.getListboxStr(), {'A','B','C'}, ...
                'The plugin set did not preserve insertion order.');

            set.movePluginAtIndexDown(1);
            testCase.verifyEqual(set.getListboxStr(), {'B','A','C'}, ...
                'movePluginAtIndexDown(1) did not swap the first two plugins.');

            set.movePluginAtIndexUp(3);
            testCase.verifyEqual(set.getListboxStr(), {'B','C','A'}, ...
                'movePluginAtIndexUp(3) did not swap the last two plugins.');

            %Ends are no-ops, not errors and not wraparounds.
            set.movePluginAtIndexUp(1);
            set.movePluginAtIndexDown(3);
            testCase.verifyEqual(set.getListboxStr(), {'B','C','A'}, ...
                'Moving the first plugin up or the last plugin down should be a no-op.');

            testCase.verifyEqual(set.getIndsForPlugins([plugins(1) plugins(3)]), [2 3], ...
                'getIndsForPlugins must report positions in set order.');
            testCase.verifyEmpty(set.getPluginAtInd(0), ...
                'getPluginAtInd(0) must return an empty array.');
            testCase.verifyEmpty(set.getPluginAtInd(4), ...
                'getPluginAtInd past the end must return an empty array.');
            testCase.verifySameHandle(set.getPluginAtInd(2), plugins(3), ...
                'getPluginAtInd did not return the plugin currently occupying that slot.');

            %Every plugin gets a distinct id from its constructor
            %(LvdPlugin.m:33), which is what the case matrix and the GUI use
            %to re-associate plugins across a save/load round trip.
            ids = [plugins.id];
            testCase.verifyEqual(numel(unique(ids)), 3, ...
                'Three separately constructed plugins did not get three distinct ids.');

            set.removePlugin(plugins(3));
            testCase.verifyEqual(set.getListboxStr(), {'B','A'}, ...
                'Removing the plugin in the middle slot did not close the gap.');

            %The graphical analysis strings are numbered by current POSITION,
            %not by insertion order or id.
            gaStrs = set.getAllPluginGraphAnalysisTaskStrs();
            testCase.verifyEqual(gaStrs, {'Plugin 1 Value - "B"', 'Plugin 2 Value - "A"'}, ...
                'The per-plugin graphical analysis task strings do not follow the current plugin order.');
        end

        function checkPluginBadWordMatchingIsWholeWordAndCaseInsensitive(testCase)
            %--------------------------------------------------------------
            % REGRESSION GUARD (two previously-fixed defects in one case)
            %
            % ORIGINAL FAULT
            %   helper_methods/ksptot_lvd/classes/Plugin/@LvdPlugin/LvdPlugin.m
            %   detected and itemised disallowed strings with two DIFFERENT
            %   predicates:
            %       tfBadWords = contains(obj.pluginCode, LvdPlugin.badWords, 'IgnoreCase',true);
            %       ...
            %           if(contains(obj.pluginCode, LvdPlugin.badWords{i}))
            %   plus a fallback that listed ALL bad words when the itemising
            %   loop found none.
            %
            %   (a) SUBSTRING MATCHING.  Neither call used a word boundary, so
            %       any identifier merely CONTAINING a listed word was
            %       rejected.  The list includes 'load', 'input', 'delete' and
            %       'dos', so ordinary spacecraft vocabulary was unusable:
            %       payloadMass, downloadRate, reload, inputCount, inputVector,
            %       deleteFlag, dosage.  For a launch vehicle tool, 'load'
            %       killing every variable named *payload* was the worst of it.
            %
            %   (b) IGNORECASE MISMATCH.  Detection was case-INsensitive and
            %       itemisation case-SENSITIVE, so code containing "SYSTEM("
            %       tripped the detector, left the index list empty, and the
            %       fallback dumped the entire seventeen-word list into the
            %       error message -- telling the user everything was banned and
            %       giving no clue which string they had actually used.
            %
            %   Both are now served by one predicate,
            %   LvdPlugin.codeUsesBadWord, which builds a case-insensitive
            %   word-boundary regexp (a bare escaped literal for symbolic
            %   entries such as "!", which have no word boundary).  Detection
            %   and itemisation call the SAME predicate, so they can no longer
            %   disagree and the all-words fallback is gone.
            %
            % COVERAGE NOTE
            %   badWords is private; its only other consumer is the LVD plugin
            %   editor GUI, which just displays the list.  So this case and
            %   checkPluginDisallowedStringBlocking above are the whole of the
            %   sandbox's coverage.
            %--------------------------------------------------------------
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            plugin = LvdPlugin();
            plugin.pluginName = 'Innocent';

            % (a) Identifiers that merely embed a disallowed word must RUN.
            innocentCode = { ...
                "payloadMass = 100; userData = payloadMass;", 100,   'load'; ...
                "downloadRate = 7; userData = downloadRate;", 7,     'load'; ...
                "inputCount = 3; userData = inputCount;",     3,     'input'; ...
                "deleteFlag = false; userData = 42;",         42,    'delete'; ...
                "dosage = 1.5; userData = dosage;",           1.5,   'dos'; ...
            };

            for(i = 1:size(innocentCode,1))
                lvdData.validation.outputs = LaunchVehicleDataValidationError.empty(1,0);
                plugin.pluginCode = innocentCode{i,1};

                out = testCase.runPlugin(plugin, lvdData, LvdPluginExecLocEnum.BeforeProp, 'untouched');

                testCase.verifyEmpty(lvdData.validation.outputs, ...
                    sprintf('Plugin code %s was rejected by the sandbox; "%s" appears only as a substring of an identifier, so the word-boundary matching in LvdPlugin.codeUsesBadWord has regressed to a bare contains().', ...
                            innocentCode{i,1}, innocentCode{i,3}));
                testCase.verifyEqual(out, innocentCode{i,2}, ...
                    sprintf('Plugin code %s did not run; userData should have come back as %g.', innocentCode{i,1}, innocentCode{i,2}));
            end

            % (b) A real call in the wrong case must be blocked, and the
            % message must name ONLY the string that was actually used.
            lvdData.validation.outputs = LaunchVehicleDataValidationError.empty(1,0);
            plugin.pluginCode = "userData = 999; x = SYSTEM('dir');";
            out = testCase.runPlugin(plugin, lvdData, LvdPluginExecLocEnum.BeforeProp, 'untouched');

            testCase.verifyEqual(out, 'untouched', ...
                'An uppercase SYSTEM(...) call was executed; the sandbox match must be case-insensitive.');
            testCase.verifyEqual(numel(lvdData.validation.outputs), 1, ...
                'Blocking an uppercase SYSTEM(...) call did not produce exactly one validation error.');

            str = lvdData.validation.outputs(1).str;
            testCase.verifySubstring(str, '"system"', ...
                'The rejection message did not name "system", the string that was actually used.');

            %This is the half that used to fail: detection and itemisation ran
            %different predicates, so the message listed every disallowed
            %string instead of the one at fault.
            badWords = LvdPlugin.getDisallowedStrings();
            for(i = 1:numel(badWords))
                if(strcmp(badWords{i}, 'system'))
                    continue;
                end

                testCase.verifyFalse(contains(str, sprintf('"%s"', badWords{i})), ...
                    sprintf('The rejection message blamed "%s" as well as "system". Detection and itemisation have gone back to using different predicates, so the all-words fallback is firing again.', badWords{i}));
            end
        end

        % ----------------------------------------------------------------
        % Case matrix
        % ----------------------------------------------------------------

        function checkCaseMatrixParameterComboEnumeration(testCase)
            %createAllTaskParamCombos (LvdCaseMatrix.m:30-81) must enumerate
            %the full Cartesian product of the supplied parameter ranges, one
            %task per combination, ordered nearest-first from the scenario's
            %current plugin variable values.  Both halves are checked against
            %hand-written oracles: refCartesianProduct instead of combvec, and
            %refNearestRowStandardizedEuclidean instead of knnsearch.
            [caseMatrix, pluginVars, lvdData] = testCase.makeCaseMatrix([3, 40, 500]);

            rangeA = [10 20 30 40];
            rangeC = [100 700];
            caseMatrix.createAllTaskParamCombos({pluginVars(1), rangeA; pluginVars(3), rangeC});

            expectedRows = refCartesianProduct({rangeA, rangeC});

            testCase.verifyEqual(numel(caseMatrix.tasks), size(expectedRows,1), ...
                sprintf('A %ux%u parameter sweep should produce %u tasks.', numel(rangeA), numel(rangeC), size(expectedRows,1)));

            actualRows = caseMatrix.tasks.getArrayOfParamValues();
            testCase.verifyEqual(size(actualRows), size(expectedRows), ...
                'The generated parameter matrix has the wrong shape.');
            testCase.verifyEqual(sortrows(actualRows), sortrows(expectedRows), 'AbsTol', 1e-12, ...
                'The set of generated parameter combinations is not the Cartesian product of the supplied ranges.');
            testCase.verifyEqual(size(unique(actualRows, 'rows'), 1), size(expectedRows,1), ...
                'The case matrix generated duplicate parameter combinations.');

            %Nearest-first ordering: task 1 must be the combination closest to
            %the scenario's current values under the standardized Euclidean
            %metric that production asks knnsearch for (LvdCaseMatrix.m:53).
            %The current values are [3, 500] on the two swept variables, so
            %the nearest row is unambiguous (no ties).
            currentVals = [pluginVars(1).value, pluginVars(3).value];
            expectedFirst = expectedRows(refNearestRowStandardizedEuclidean(expectedRows, currentVals), :);
            testCase.verifyEqual(actualRows(1,:), expectedFirst, 'AbsTol', 1e-12, ...
                sprintf('The first generated task should be the combination nearest the scenario''s current plugin variable values [%g %g].', currentVals(1), currentVals(2)));

            %Only the swept variables appear.  pluginVars(2) was not swept, so
            %the used-mask must exclude it and the rows must be 2 wide.
            testCase.verifyEqual(caseMatrix.tasks(1).pluginVarIsUsed, [true false true], ...
                'The per-task plugin variable mask does not mark exactly the swept variables.');

            %Each task knows its own position and gets its own file name and id.
            filePaths = {caseMatrix.tasks.lvdFilePath};
            testCase.verifyEqual(numel(unique(filePaths)), numel(filePaths), ...
                'Two tasks were given the same .mat file path.');
            testCase.verifyEqual(numel(unique([caseMatrix.tasks.id])), numel(caseMatrix.tasks), ...
                'Tasks did not get distinct ids.');
            for(i = 1:numel(caseMatrix.tasks))
                testCase.verifyEqual(caseMatrix.tasks(i).caseNumber, i, ...
                    sprintf('Task %u reported the wrong caseNumber.', i));
                testCase.verifySameHandle(caseMatrix.tasks(i).caseMatrix, caseMatrix, ...
                    sprintf('Task %u does not point back at the case matrix that created it.', i));
                testCase.verifyEqual(caseMatrix.tasks(i).status, LvdCaseMatrixTaskStatusEnum.NotRun, ...
                    sprintf('Freshly generated task %u was not in the NotRun state.', i));
            end

            %Every task is generated with a TaskCreated notification carrying
            %its index and the total (LvdCaseMatrix.m:76-77).  The GUI's
            %progress bar is driven entirely by this pair, so an off-by-one
            %in either would be invisible except as a wrong progress readout.
            observedCounts = zeros(0,2);
            observedTasks = {};

            caseMatrix2 = LvdCaseMatrix(lvdData, tempdir());
            lh = addlistener(caseMatrix2, 'TaskCreated', @recordTaskCreated);
            caseMatrix2.createAllTaskParamCombos({pluginVars(1), [5 6 7]});
            delete(lh);

            testCase.verifyEqual(observedCounts, [1 3; 2 3; 3 3], ...
                'The TaskCreated event did not fire once per task with (taskNum, totalTasks) counting 1..N of N.');
            testCase.verifyEqual(numel(observedTasks), 3, ...
                'The TaskCreated event did not carry a task handle for every task.');
            for(i = 1:3)
                testCase.verifySameHandle(observedTasks{i}, caseMatrix2.tasks(i), ...
                    sprintf('The TaskCreated event for task %u carried the wrong task handle.', i));
            end

            %A single-valued sweep is still a sweep.
            caseMatrix3 = LvdCaseMatrix(lvdData, tempdir());
            caseMatrix3.createAllTaskParamCombos({pluginVars(2), 42});
            testCase.verifyEqual(numel(caseMatrix3.tasks), 1, ...
                'A one-value parameter range should produce exactly one task.');
            testCase.verifyEqual(caseMatrix3.tasks(1).getArrayOfParamValues(), 42, ...
                'The single generated task does not carry the single swept value.');

            %LvdCaseMatrixTaskParameter.updatePluginVar pushes the value into
            %the plugin variable and pins it (LvdCaseMatrixTaskParameter.m:20-23).
            pluginVars(2).setIfVariableIsActive(true);
            param = LvdCaseMatrixTaskParameter(pluginVars(2), 999);
            param.updatePluginVar();
            testCase.verifyEqual(pluginVars(2).value, 999, ...
                'updatePluginVar did not write the case value into the plugin variable.');
            testCase.verifyFalse(pluginVars(2).isVariableActive(), ...
                'updatePluginVar must deactivate the optimisation variable so the optimiser cannot move a swept parameter off its case value.');

            function recordTaskCreated(~, evt)
                %A nested function rather than an anonymous one: the listener
                %has to accumulate into the enclosing workspace, which an
                %anonymous function cannot do.
                observedCounts(end+1, :) = [evt.taskNum, evt.totalTasks]; %#ok<AGROW>
                observedTasks{end+1} = evt.task; %#ok<AGROW>
            end
        end

        function checkCaseMatrixTaskStateMachine(testCase)
            %The run loop in runAllTasks is driven entirely by the predicates
            %below (LvdCaseMatrix.m:134-214).  runAllTasks itself needs a
            %parallel pool and writes files, so it is skipped; the decision
            %logic it consults is driven by hand here.  maxNumAttempts is the
            %retry budget: a Failed task is re-runnable while
            %numAttempts < maxNumAttempts.
            [caseMatrix, pluginVars] = testCase.makeCaseMatrix([3, 40, 500]);
            caseMatrix.createAllTaskParamCombos({pluginVars(1), [10 20 30 40]});
            tasks = caseMatrix.tasks;

            testCase.verifyEqual(caseMatrix.maxNumAttempts, 2, ...
                'The default retry budget is no longer 2; the expectations below assume it is.');

            %All NotRun.
            testCase.verifyTrue(caseMatrix.areThereUnrunTasks(), ...
                'A freshly generated case matrix reported no unrun tasks.');
            testCase.verifyFalse(caseMatrix.areAllJobsDone(), ...
                'A freshly generated case matrix reported all jobs done.');
            testCase.verifyTrue(caseMatrix.keepLoopingOverJobs(), ...
                'A freshly generated case matrix told the run loop to stop.');
            testCase.verifyEqual(caseMatrix.getNumOfRunningJobs(), 0, ...
                'A freshly generated case matrix reported running jobs.');
            testCase.verifySameHandle(caseMatrix.getNextUnRunTask(), tasks(1), ...
                'getNextUnRunTask did not hand back the first NotRun task.');

            %Mark one running.  setTaskStatusAsRunning also burns an attempt
            %and stamps a message (LvdCaseMatrixTask.m:88-92).
            tasks(1).setTaskStatusAsRunning();
            testCase.verifyEqual(tasks(1).status, LvdCaseMatrixTaskStatusEnum.Running, ...
                'setTaskStatusAsRunning did not move the task to Running.');
            testCase.verifyEqual(tasks(1).numAttempts, 1, ...
                'setTaskStatusAsRunning did not increment the attempt counter.');
            testCase.verifyEqual(tasks(1).taskOutputMessage, 'Running...', ...
                'setTaskStatusAsRunning did not stamp the in-progress message.');
            testCase.verifyEqual(caseMatrix.getNumOfRunningJobs(), 1, ...
                'One running task was not counted.');
            testCase.verifySameHandle(caseMatrix.getNextUnRunTask(), tasks(2), ...
                'getNextUnRunTask handed back a task that is already Running.');

            %Success and the three failure flavours (LvdCaseMatrixTask.m:100-113).
            tasks(1).setTaskAsFinished(LvdCaseMatrixTaskRunStatusEnum.RunSuceeded, 'converged');
            testCase.verifyEqual(tasks(1).status, LvdCaseMatrixTaskStatusEnum.Completed, ...
                'A successful run did not mark the task Completed.');
            testCase.verifyEqual(tasks(1).taskOutputMessage, 'converged', ...
                'setTaskAsFinished did not record the run message.');

            failureModes = [LvdCaseMatrixTaskRunStatusEnum.RunFailedDueToError, ...
                            LvdCaseMatrixTaskRunStatusEnum.RunFailedOptimizerNotConverged, ...
                            LvdCaseMatrixTaskRunStatusEnum.RunFailedPreReqNotSatisfied];
            for(i = 1:numel(failureModes))
                tasks(2).setTaskAsFinished(failureModes(i), 'nope');
                testCase.verifyEqual(tasks(2).status, LvdCaseMatrixTaskStatusEnum.Failed, ...
                    sprintf('Run status %s should map to the Failed task status.', failureModes(i).name));
            end

            %Retry budget.
            tasks(2).setTaskStatusAsRunning();
            tasks(2).setTaskAsFinished(LvdCaseMatrixTaskRunStatusEnum.RunFailedDueToError, 'nope');
            testCase.verifyEqual(tasks(2).numAttempts, 1, ...
                'Fixture broken: the failed task should have used exactly one attempt.');
            testCase.verifyEqual(numel(caseMatrix.getFailedJobsThatCanBeRerun()), 1, ...
                'A task that failed on its first of two allowed attempts should be re-runnable.');
            testCase.verifyTrue(caseMatrix.areThereUnrunTasks(), ...
                'A re-runnable failed task should count as outstanding work.');

            tasks(2).numAttempts = caseMatrix.maxNumAttempts;
            testCase.verifyEmpty(caseMatrix.getFailedJobsThatCanBeRerun(), ...
                'A task that has exhausted its retry budget should not be offered for re-run.');

            %setTaskAsUnRun rewinds everything (LvdCaseMatrixTask.m:115-119).
            tasks(2).setTaskAsUnRun();
            testCase.verifyEqual(tasks(2).status, LvdCaseMatrixTaskStatusEnum.NotRun, ...
                'setTaskAsUnRun did not reset the status.');
            testCase.verifyEqual(tasks(2).numAttempts, 0, ...
                'setTaskAsUnRun did not reset the attempt counter.');
            testCase.verifyEmpty(tasks(2).taskOutputMessage, ...
                'setTaskAsUnRun did not clear the output message.');

            %Drive everything to a terminal state and confirm the loop stops.
            for(i = 2:numel(tasks))
                tasks(i).setTaskStatusAsRunning();
                tasks(i).setTaskAsFinished(LvdCaseMatrixTaskRunStatusEnum.RunSuceeded, 'ok');
            end
            testCase.verifyTrue(caseMatrix.areAllJobsDone(), ...
                'With every task Completed, areAllJobsDone should be true.');
            testCase.verifyFalse(caseMatrix.areThereUnrunTasks(), ...
                'With every task Completed, there should be no unrun tasks.');
            testCase.verifyFalse(caseMatrix.keepLoopingOverJobs(), ...
                'With every task Completed, the run loop should stop.');
            testCase.verifyEmpty(caseMatrix.getNextUnRunTask(), ...
                'With every task Completed, getNextUnRunTask should hand back nothing.');

            %Completeness of the mapping.  setTaskAsFinished switches over
            %LvdCaseMatrixTaskRunStatusEnum and falls through to
            %error('Unknown or unexpected run status: %s', ...) at
            %LvdCaseMatrixTask.m:108-110.  Every one of the four enum members
            %is handled by one of the two arms above, which is exactly why
            %that "otherwise" arm is not exercised here: with a well-typed
            %argument it is unreachable, and reaching it takes a degenerate
            %value (an empty enum array) whose failure mode is an artefact of
            %switch semantics rather than of this class.  What IS worth
            %asserting is that the mapping stays exhaustive, so that adding a
            %fifth run status without extending the switch shows up here.
            runStatuses = enumeration('LvdCaseMatrixTaskRunStatusEnum');
            testCase.verifyEqual(numel(runStatuses), 4, ...
                'LvdCaseMatrixTaskRunStatusEnum gained or lost a member; setTaskAsFinished must map every one of them to a task status or it will fall through to its "Unknown or unexpected run status" error at run time.');

            expectedMapping = { ...
                LvdCaseMatrixTaskRunStatusEnum.RunSuceeded,                    LvdCaseMatrixTaskStatusEnum.Completed; ...
                LvdCaseMatrixTaskRunStatusEnum.RunFailedDueToError,            LvdCaseMatrixTaskStatusEnum.Failed; ...
                LvdCaseMatrixTaskRunStatusEnum.RunFailedOptimizerNotConverged, LvdCaseMatrixTaskStatusEnum.Failed; ...
                LvdCaseMatrixTaskRunStatusEnum.RunFailedPreReqNotSatisfied,    LvdCaseMatrixTaskStatusEnum.Failed; ...
            };
            testCase.verifyEqual(numel(runStatuses), size(expectedMapping,1), ...
                'The run-status-to-task-status mapping asserted below no longer covers every LvdCaseMatrixTaskRunStatusEnum member.');
            for(i = 1:size(expectedMapping,1))
                tasks(1).setTaskAsFinished(expectedMapping{i,1}, 'x');
                testCase.verifyEqual(tasks(1).status, expectedMapping{i,2}, ...
                    sprintf('Run status %s should map to task status %s.', expectedMapping{i,1}.name, expectedMapping{i,2}.name));
            end
        end

        function checkCaseMatrixPrereqsCancelAndUiTable(testCase)
            %Prerequisites, cancellation and the UI table projection.
            [caseMatrix, pluginVars] = testCase.makeCaseMatrix([3, 40, 500]);
            caseMatrix.createAllTaskParamCombos({pluginVars(1), [10 20 30]});
            tasks = caseMatrix.tasks;

            %A task with no prerequisites is always runnable
            %(LvdCaseMatrixTask.m:263-276).
            for(i = 1:numel(tasks))
                testCase.verifyTrue(tasks(i).areAllPreReqsSatisfied(), ...
                    sprintf('Task %u has no prerequisites but reported them unsatisfied.', i));
            end

            %Chain 3 behind 1 and 2.  Only Completed counts as satisfied --
            %Failed does not.
            tasks(3).prereqTasks = [tasks(1) tasks(2)];
            testCase.verifyFalse(tasks(3).areAllPreReqsSatisfied(), ...
                'A task whose prerequisites are still NotRun reported them satisfied.');

            tasks(1).status = LvdCaseMatrixTaskStatusEnum.Completed;
            testCase.verifyFalse(tasks(3).areAllPreReqsSatisfied(), ...
                'A task with one of two prerequisites complete reported them all satisfied.');

            tasks(2).status = LvdCaseMatrixTaskStatusEnum.Failed;
            testCase.verifyFalse(tasks(3).areAllPreReqsSatisfied(), ...
                'A Failed prerequisite must not count as satisfied.');

            tasks(2).status = LvdCaseMatrixTaskStatusEnum.Completed;
            testCase.verifyTrue(tasks(3).areAllPreReqsSatisfied(), ...
                'With both prerequisites Completed the dependent task should be runnable.');

            %Cancellation flips the flag and moves running tasks to Canceled
            %(LvdCaseMatrix.m:306-324).  Tasks that are not running are left
            %alone.  Note gcp('nocreate') returns empty here, so cancelRun
            %takes its no-pool path.
            [caseMatrix2, pluginVars2] = testCase.makeCaseMatrix([3, 40, 500]);
            caseMatrix2.createAllTaskParamCombos({pluginVars2(1), [10 20 30]});
            caseMatrix2.tasks(2).setTaskStatusAsRunning();

            caseMatrix2.cancelRun();
            testCase.verifyTrue(caseMatrix2.runCanceled, ...
                'cancelRun did not set the runCanceled flag the run loop polls.');
            testCase.verifyEqual(caseMatrix2.tasks(2).status, LvdCaseMatrixTaskStatusEnum.Canceled, ...
                'cancelRun did not move the running task to Canceled.');
            testCase.verifyEqual(caseMatrix2.tasks(2).taskOutputMessage, 'Canceled', ...
                'cancelRun did not stamp the Canceled message.');
            testCase.verifyEqual(caseMatrix2.tasks(1).status, LvdCaseMatrixTaskStatusEnum.NotRun, ...
                'cancelRun altered the status of a task that was not running.');

            %getUITableData is one row per task: index, one column per swept
            %parameter, then status name and message (LvdCaseMatrix.m:291-304).
            [caseMatrix3, pluginVars3] = testCase.makeCaseMatrix([3, 40, 500]);
            caseMatrix3.createAllTaskParamCombos({pluginVars3(1), [10 20]; pluginVars3(3), [100 700]});
            caseMatrix3.tasks(1).setTaskStatusAsRunning();
            caseMatrix3.tasks(1).setTaskAsFinished(LvdCaseMatrixTaskRunStatusEnum.RunSuceeded, 'yay');

            data = caseMatrix3.getUITableData();
            testCase.verifyEqual(size(data), [4 5], ...
                'The UI table should be one row per task and one column for the index, each swept parameter, the status and the message.');
            for(i = 1:4)
                testCase.verifyEqual(data{i,1}, i, ...
                    sprintf('UI table row %u does not carry its own case number in column 1.', i));
                testCase.verifyEqual([data{i,2}, data{i,3}], caseMatrix3.tasks(i).getArrayOfParamValues(), ...
                    sprintf('UI table row %u does not carry that task''s parameter values.', i));
                testCase.verifyEqual(data{i,4}, caseMatrix3.tasks(i).status.name, ...
                    sprintf('UI table row %u does not carry that task''s status name.', i));
                testCase.verifyEqual(data{i,5}, caseMatrix3.tasks(i).taskOutputMessage, ...
                    sprintf('UI table row %u does not carry that task''s output message.', i));
            end
            testCase.verifyEqual(data{1,4}, 'Completed', ...
                'The completed task''s UI row does not say Completed.');
            testCase.verifyEqual(data{2,4}, 'Not Run', ...
                'An untouched task''s UI row does not say Not Run.');
        end

        function checkCaseMatrixCaseFileZeroPadWidthIsUniform(testCase)
            %--------------------------------------------------------------
            % REGRESSION GUARD (previously-fixed defect)
            %
            % ORIGINAL FAULT
            %   helper_methods/ksptot_lvd/classes/CaseMatrix/@LvdCaseMatrix/
            %       LvdCaseMatrix.m:55
            %       numDigits = ceil(log10(abs(max(Idx))));
            %   consumed at line 70 as the width in
            %       sprintf('Case_%0*u.mat', numDigits, i)
            %   ceil(log10(N)) is one short of floor(log10(N)) + 1 whenever N
            %   is an exact power of ten, and is 0 for N = 1:
            %       N = 10  -> width 1 -> Case_1 .. Case_10
            %       N = 100 -> width 2 -> Case_01 .. Case_100
            %       N = 11  -> width 2 -> Case_01 .. Case_11   (correct)
            %   So the padding was right for every case count EXCEPT exact
            %   powers of ten -- precisely the sweep sizes a user picks.  The
            %   damage was cosmetic (the paths stayed unique, which
            %   checkCaseMatrixParameterComboEnumeration asserts), but the
            %   .mat files, the .xlsx sheet names derived from them and the
            %   .log files beside them all listed out of lexicographic order.
            %
            %   Line 55 now reads floor(log10(abs(max(Idx)))) + 1.  The powers
            %   of ten below are the cases that used to fail; the others are
            %   there so a fix that over-corrects is caught too.
            %
            % COVERAGE NOTE
            %   numDigits is local to createAllTaskParamCombos and line 70 is
            %   its only use, but runAllTasks (line 96) and processTaskOutputs
            %   (line 340) both derive their own file names from that path, so
            %   they inherit whatever width it chooses.
            %--------------------------------------------------------------
            [caseMatrix, pluginVars, lvdData] = testCase.makeCaseMatrix([3, 40, 500]); %#ok<ASGLU>

            %Uniform width for every case count, powers of ten included.
            expectedWidths = [1 1; 9 1; 10 2; 11 2; 99 2; 100 3];
            for(i = 1:size(expectedWidths,1))
                n = expectedWidths(i,1);
                expDigits = expectedWidths(i,2);

                names = testCase.caseFileNames(lvdData, pluginVars(1), n);

                testCase.verifyEqual(numel(names), n, ...
                    sprintf('Requesting %u cases produced %u case files.', n, numel(names)));
                testCase.verifyEqual(numel(unique(cellfun(@numel, names))), 1, ...
                    sprintf('With %u cases the file names are not all the same length, so they will not sort lexicographically. Check whether LvdCaseMatrix.m:55 went back to ceil(log10(N)).', n));

                %The width itself, not just its uniformity: padding everything
                %to some other constant would satisfy the check above.
                testCase.verifyEqual(numel(names{1}), numel('Case_') + expDigits, ...
                    sprintf('With %u cases the file names should be zero padded to %u digit(s).', n, expDigits));
                testCase.verifyEqual(names{1}, sprintf('Case_%0*u', expDigits, 1), ...
                    sprintf('With %u cases the first file should be named %s.', n, sprintf('Case_%0*u', expDigits, 1)));
                testCase.verifyEqual(names{end}, sprintf('Case_%0*u', expDigits, n), ...
                    sprintf('With %u cases the last file should be named %s.', n, sprintf('Case_%0*u', expDigits, n)));
            end
        end

        % ----------------------------------------------------------------
        % Graphical analysis task layer (spot check)
        % ----------------------------------------------------------------

        function checkGraphAnalysisTaskListComposition(testCase)
            %lvd_getGraphAnalysisTaskList takes the shared Mission Architect
            %task list, subtracts everything LVD cannot support, re-adds the
            %LVD-native names and appends one entry per user-defined object.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            excludeList = getLvdGAExcludeList();

            taskList = lvd_getGraphAnalysisTaskList(lvdData, excludeList);

            testCase.verifyNotEmpty(taskList, ...
                'The graphical analysis task list came back empty.');
            testCase.verifyEqual(numel(unique(taskList)), numel(taskList), ...
                'The graphical analysis task list contains duplicate entries; an LVD-native name is shadowing a Mission Architect one.');
            testCase.verifyEqual(taskList(:), sort(taskList(:)), ...
                'The graphical analysis task list is not sorted (lvd_getGraphAnalysisTaskList.m:156 sorts it, and the GUI listbox relies on that).');

            %LVD-native names appended by lvd_getGraphAnalysisTaskList must be
            %present.
            mustHave = {'Throttle', 'Event Number', 'Total Thrust', 'Yaw Angle', ...
                        'Pitch Angle', 'Roll Angle', 'Bank Angle', 'Drag Force', ...
                        'Height Above Terrain', 'Thrust to Weight Ratio', ...
                        'Two-Body Impact Latitude', 'Total Body Angular Rate', ...
                        'Semi-major Axis', 'Altitude', 'Latitude (North)'};
            for(i = 1:numel(mustHave))
                testCase.verifyTrue(any(strcmp(taskList, mustHave{i})), ...
                    sprintf('The LVD graphical analysis task list is missing "%s".', mustHave{i}));
            end

            %Excluded names that LVD does NOT re-add must be gone.  These are
            %all Mission Architect concepts with no LVD equivalent (reference
            %spacecraft, reference stations, hard-coded fluid types).
            mustNotHave = {'Distance to Ref. Spacecraft', 'Distance to Ref. Station', ...
                           'Relative Vel. to Ref. Spacecraft', 'Relative SMA of Ref. Spacecraft', ...
                           'Elevation Angle w.r.t. Ref. Station', 'Line of Sight to Ref. Station', ...
                           'Line of Sight to Ref. Spacecraft', 'Sun-centric Position (X)', ...
                           'Body-centric Position (X)', 'Body-Fixed Velocity', ...
                           'Radius of Spacecraft', 'Speed of Spacecraft', ...
                           'Distance to Ref. Celestial Body', 'Liquid Fuel/Ox Mass', ...
                           'Monopropellant Mass', 'Xenon Mass'};
            for(i = 1:numel(mustNotHave))
                testCase.verifyTrue(any(strcmp(excludeList, mustNotHave{i})), ...
                    sprintf('Test assumption broken: "%s" is no longer on the LVD exclusion list.', mustNotHave{i}));
                testCase.verifyFalse(any(strcmp(taskList, mustNotHave{i})), ...
                    sprintf('"%s" is on the LVD exclusion list but survived into the task list.', mustNotHave{i}));
            end

            %Adding ground objects adds exactly four entries each -- azimuth,
            %elevation, range and line of sight -- named after the object.
            baseCount = numel(taskList);
            grdObj = LaunchVehicleGroundObject.getDefaultObj(testCase.celBodyData);
            grdObj.name = 'Woomera';
            lvdData.groundObjs.addGroundObj(grdObj);

            taskList2 = lvd_getGraphAnalysisTaskList(lvdData, excludeList);
            testCase.verifyEqual(numel(taskList2), baseCount + 4, ...
                'Adding one ground object should add exactly four graphical analysis tasks (azimuth, elevation, range, line of sight).');

            ind = lvdData.groundObjs.getIndsForGroundObjs(grdObj);
            for(pattern = {'Azimuth to S/C', 'Elevation to S/C', 'Range to S/C', 'Line of Sight to S/C'})
                expected = sprintf('Ground Object %u %s - "Woomera"', ind, pattern{1});
                testCase.verifyTrue(any(strcmp(taskList2, expected)), ...
                    sprintf('The task list is missing the expected per-ground-object entry "%s".', expected));
            end

            %Same for plugins and plugin variables.
            plugin = LvdPlugin();
            plugin.pluginName = 'Telemetry';
            lvdData.plugins.addPlugin(plugin);

            pluginVar = LvdPluginOptimVarWrapper();
            pluginVar.name = 'Gain';
            lvdData.pluginVars.addPluginVar(pluginVar);

            taskList3 = lvd_getGraphAnalysisTaskList(lvdData, excludeList);
            testCase.verifyEqual(numel(taskList3), baseCount + 6, ...
                'Adding one plugin and one plugin variable should add exactly one graphical analysis task each.');
            testCase.verifyTrue(any(strcmp(taskList3, 'Plugin 1 Value - "Telemetry"')), ...
                'The task list is missing the per-plugin graphical analysis entry.');
            testCase.verifyTrue(any(strcmp(taskList3, 'Plugin Variable 1 Value - "Gain"')), ...
                'The task list is missing the per-plugin-variable graphical analysis entry.');
        end

        function checkGraphAnalysisEventNumAndThrottleTasks(testCase)
            %Spot check of two task dispatchers whose outputs are checkable
            %without redoing a propagation.  The state log entries are
            %synthesised rather than propagated: what is under test is the
            %dispatch layer's plumbing (which state log field each task reads,
            %and in what units it reports it), not the trajectory.
            [entries, events] = testCase.makeTaggedEntries();
            frame = testCase.kerbinFrame;

            %lvd_EventNumTask reads element 13 of the Mission Architect state
            %log row (lvd_EventNumTask.m:8).  That index must line up with
            %LaunchVehicleStateLogEntry.getMAFormattedStateLogMatrix:160,
            %which is the only place it is written -- an off-by-one there
            %would silently report a propellant mass as the event number.
            sawEvent = false(1,2);
            for(i = 1:numel(entries))
                entry = entries(i);
                expectedEvtNum = entry.event.getEventNum();

                testCase.verifyEqual(lvd_EventNumTask(entry, 'eventNum'), expectedEvtNum, ...
                    sprintf('The Event Number graphical analysis task disagreed with event.getEventNum() at state log entry %u.', i));

                maRow = entry.getMAFormattedStateLogMatrix(false);
                testCase.verifyEqual(numel(maRow), 13, ...
                    'The Mission Architect state log row is no longer 13 wide; lvd_EventNumTask.m:8 indexes element 13.');
                testCase.verifyEqual(maRow(1), entry.time, 'AbsTol', 1e-12, ...
                    'Element 1 of the Mission Architect state log row is not the time; the row layout has changed.');
                testCase.verifyEqual(maRow(8), entry.centralBody.id, ...
                    'Element 8 of the Mission Architect state log row is not the central body id; the row layout has changed.');

                sawEvent(expectedEvtNum) = true;
            end
            testCase.verifyEqual(numel(events), 2, ...
                'Fixture broken: the two-event script did not come back with two events.');
            testCase.verifyTrue(all(sawEvent), ...
                'Fixture broken: the entries were not tagged to two different events, so the Event Number task was never asked to distinguish them.');

            %lvd_ThrottleTask 'throttle' reports PERCENT, not a 0-1 fraction
            %(lvd_ThrottleTask.m:7).
            entry = entries(1);
            for(frac = [0, 0.37, 1])
                testCase.setThrottle(entry, frac);
                testCase.verifyEqual(lvd_ThrottleTask(entry, 'throttle', frame), 100*frac, 'AbsTol', 1e-12, ...
                    sprintf('A throttle fraction of %g should be reported as %g percent by the Throttle graphical analysis task.', frac, 100*frac));
            end

            %An unrecognised sub-task is a programming error and must not
            %return a plausible-looking number (lvd_ThrottleTask.m:78).
            caught = MException.empty(1,0);
            try
                lvd_ThrottleTask(entry, 'no-such-subtask', frame); %#ok<NASGU>
            catch ME
                caught = ME;
            end
            testCase.verifyNotEmpty(caught, ...
                'lvd_ThrottleTask accepted an unrecognised sub-task string.');
            testCase.verifySubstring(caught.message, 'no-such-subtask', ...
                'The unrecognised sub-task error does not name the sub-task that was asked for.');
        end

        % ----------------------------------------------------------------
        % Fixtures
        % ----------------------------------------------------------------

        function grdObj = makeGroundObject(testCase, numWayPts)
            %makeGroundObject Kerbin-fixed ground object with 1 or 3 waypoints.
            %
            %The three-waypoint layout is deliberate:
            %  wp1 (0 N,   0 E,  0 km) --100 s--> wp2 (0 N,  90 E, 10 km)
            %  wp2                     --200 s--> wp3 (45 N, 180 E, 20 km)
            %  wp3                     --300 s--> wp1  (looping only)
            %Leg 1 is a pure equatorial quarter turn, so its great-circle
            %geometry is exactly known by hand (latitude stays 0, longitude
            %advances uniformly).  Legs 2 and 3 are oblique, so a mistake that
            %only shows up off the equator is still caught.  The three leg
            %durations are all different so no scheduling error can hide
            %behind symmetry.
            ksptotAddProjectPaths();
            frame = testCase.kerbin.getBodyFixedFrame();

            wayPts = LaunchVehicleGroundObjectWayPt.empty(1,0);
            wayPts(1) = LaunchVehicleGroundObjectWayPt( ...
                GeographicElementSet(0, 0, 0, 0, 0,0,0, frame), testCase.Leg1);

            if(numWayPts > 1)
                wayPts(2) = LaunchVehicleGroundObjectWayPt( ...
                    GeographicElementSet(0, 0, deg2rad(90), 10, 0,0,0, frame), testCase.Leg2);
                wayPts(3) = LaunchVehicleGroundObjectWayPt( ...
                    GeographicElementSet(0, deg2rad(45), deg2rad(180), 20, 0,0,0, frame), testCase.Leg3);
            end

            grdObj = LaunchVehicleGroundObject('Test Ground Object', "", 0, wayPts(1:numWayPts));
        end

        function userData = runPlugin(~, plugin, lvdData, execLoc, userDataIn)
            %runPlugin Calls LvdPlugin.executePlugin with the eleven-argument
            %signature (LvdPlugin.m:36), filling in the arguments the exec
            %locations under test do not use.
            userData = plugin.executePlugin(lvdData, [], LaunchVehicleEvent.empty(0,1), ...
                                            execLoc, [], [], [], userDataIn, [], []);
        end

        function [caseMatrix, pluginVars, lvdData] = makeCaseMatrix(testCase, currentValues)
            %makeCaseMatrix Scenario with three plugin variables at the given
            %current values, plus an empty case matrix pointed at the system
            %temp directory.
            %
            %Nothing in the tests that use this writes to disk: the case
            %matrix only COMPOSES file paths (LvdCaseMatrix.m:70).  Saving and
            %loading is LvdCaseMatrixTask's lvdData property, which is out of
            %scope (see the SKIPPED block in the class header).
            ksptotAddProjectPaths();
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            names = {'Alpha', 'Beta', 'Gamma'};
            pluginVars = LvdPluginOptimVarWrapper.empty(1,0);
            for(i = 1:3)
                pluginVars(i) = LvdPluginOptimVarWrapper();
                pluginVars(i).name = names{i};
                pluginVars(i).value = currentValues(i);
                pluginVars(i).optVar = pluginVars(i).getNewOptVar();
                lvdData.pluginVars.addPluginVar(pluginVars(i));
            end

            caseMatrix = LvdCaseMatrix(lvdData, tempdir());
        end

        function names = caseFileNames(~, lvdData, pluginVar, numCases)
            %caseFileNames Generates numCases cases and returns the bare file
            %names (no directory, no extension) the case matrix chose.
            caseMatrix = LvdCaseMatrix(lvdData, tempdir());
            caseMatrix.createAllTaskParamCombos({pluginVar, 1:numCases});

            names = cell(1, numel(caseMatrix.tasks));
            for(i = 1:numel(caseMatrix.tasks))
                [~, names{i}, ~] = fileparts(caseMatrix.tasks(i).lvdFilePath);
            end
        end

        function [entries, events] = makeTaggedEntries(testCase)
            %makeTaggedEntries Three state log entries over a two-event
            %script: two tagged to event 1 and one to event 2.
            %
            %Nothing is propagated.  The graphical analysis dispatchers under
            %test read fields off a single state log entry, so a synthesised
            %entry exercises exactly the same code with none of the cost or
            %the coupling to the integrator.
            ksptotAddProjectPaths();
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            template = lvdData.initStateModel.getInitialStateLogEntry();

            evt1 = lvdData.script.getEventForInd(1);

            evt2 = LaunchVehicleEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(600);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);

            events = [evt1, evt2];

            %Every entry is a deep copy: LVD is handle classes throughout, so
            %sharing one entry would make the per-entry assertions vacuous.
            entries = LaunchVehicleStateLogEntry.empty(1,0);
            taggedTo = [1 1 2];
            times = [0 300 600];
            for(i = 1:3)
                entries(i) = template.deepCopy();
                entries(i).event = events(taggedTo(i));
                entries(i).time = times(i);
            end

            testCase.assertEqual(evt1.getEventNum(), 1, ...
                'Fixture broken: the first script event does not report event number 1.');
            testCase.assertEqual(evt2.getEventNum(), 2, ...
                'Fixture broken: the appended script event does not report event number 2.');
        end

        function setThrottle(testCase, entry, frac)
            %setThrottle Drives a state log entry's throttle to a known
            %fraction by installing a FRESH constant polynomial model.
            %
            %A fresh model rather than a mutation of the existing one:
            %LaunchVehicleStateLogEntry.deepCopy copies the throttle model
            %HANDLE rather than cloning it, so every entry deep copied from
            %one template shares a single model object and writing through it
            %would change all of them at once.
            testCase.assertClass(entry.throttleModel, 'ThrottlePolyModel', ...
                'setThrottle assumes the stock polynomial throttle model.');

            model = ThrottlePolyModel.getDefaultThrottleModel();
            model.throttleModel.constTerm = frac;
            entry.throttleModel = model;

            testCase.assertEqual(entry.throttle, frac, 'AbsTol', 1e-12, ...
                'setThrottle failed to move the entry throttle.');
        end
    end
end

% --------------------------------------------------------------------
% Independent oracles
% --------------------------------------------------------------------

function delta = refCentralAngle(lat1, long1, lat2, long2)
    %refCentralAngle Great-circle central angle, in radians, by haversine.
    %
    %Production uses the Mapping Toolbox distance(...,'radians').  This is a
    %deliberately different formula for the same quantity: haversine is the
    %numerically well-conditioned form for small separations, and writing it
    %out here means a change of convention in distance() (degrees vs radians,
    %or a switch to an ellipsoidal model) shows up as a test failure rather
    %than propagating silently into every ground track in the tool.
    dLat = lat2 - lat1;
    dLong = long2 - long1;

    h = sin(dLat/2)^2 + cos(lat1)*cos(lat2)*sin(dLong/2)^2;
    delta = 2*asin(min(1, sqrt(h)));
end

function [lat, long] = refSlerp(lat1, long1, lat2, long2, f, delta)
    %refSlerp Spherical linear interpolation with an EXPLICIT central angle.
    %
    %delta is a parameter rather than something computed here on purpose: the
    %correctness tests pass the true central angle and the bug pin passes
    %(true central angle)/(body radius), which is what production actually
    %uses.  One implementation, two call sites, so the pin and the positive
    %test can never disagree about what the formula is -- only about what
    %delta should be, which is precisely the defect.
    u1 = [cos(lat1)*cos(long1); cos(lat1)*sin(long1); sin(lat1)];
    u2 = [cos(lat2)*cos(long2); cos(lat2)*sin(long2); sin(lat2)];

    a = sin((1-f)*delta) / sin(delta);
    b = sin(f*delta)     / sin(delta);

    v = a*u1 + b*u2;

    lat = atan2(v(3), hypot(v(1), v(2)));
    long = atan2(v(2), v(1));
end

function rows = refCartesianProduct(ranges)
    %refCartesianProduct Every combination of one element from each range, as
    %rows.  Production uses combvec (Deep Learning Toolbox); this is plain
    %nested iteration so the two cannot share a bug.
    rows = zeros(1, 0);
    for(i = 1:numel(ranges))
        r = ranges{i};
        r = r(:);

        n = size(rows, 1);
        if(n == 0)
            rows = r;
        else
            rows = [repmat(rows, numel(r), 1), repelem(r, n, 1)]; %#ok<AGROW>
        end
    end
end

function idx = refNearestRowStandardizedEuclidean(rows, query)
    %refNearestRowStandardizedEuclidean Index of the row of `rows` closest to
    %`query` under the standardized Euclidean metric, i.e. each column divided
    %by that column's sample standard deviation before the ordinary Euclidean
    %distance is taken.  That is the metric production asks knnsearch for at
    %LvdCaseMatrix.m:53 ('Distance','seuclidean'); this spells it out rather
    %than calling knnsearch.
    s = std(rows, 0, 1);
    s(s == 0) = 1;   %a constant column contributes nothing either way

    scaledRows = rows ./ s;
    scaledQuery = query(:)' ./ s;

    d = sum((scaledRows - scaledQuery).^2, 2);
    [~, idx] = min(d);
end
