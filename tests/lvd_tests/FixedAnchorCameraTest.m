classdef FixedAnchorCameraTest < KsptotTestCase
    %FixedAnchorCameraTest The "Fixed Camera (Tracking)" anchor of the LVD
    %3-D view (F8): a camera fixed at an anchor (a coordinate in a chosen
    %frame, a ground object, or a geometric point) that keeps the vehicle
    %centred.  Covers anchor resolution into the view frame, the tracking
    %pose geometry, graceful [] fallbacks, loadobj upgrade and the
    %"set from current camera" round trip.

    methods(Test)

        %% ----------------------------------------------- fixed XYZ anchor

        function fixedXyzWithEmptyFrameIsVerbatimInTheViewFrame(testCase)
            fa = LvdFixedAnchorCameraSettings();
            fa.fixedPosition = [1234 -56 78];   %anchorFrame left empty
            viewFrame = testCase.kerbinFrame;

            pos = fa.getAnchorPosAtTime(0, viewFrame);
            testCase.verifyVectorEqual(pos', [1234 -56 78], 1e-9, ...
                'An empty anchor frame means the coordinate is the view-frame position.');
        end

        function fixedXyzInTheViewFrameMatchesTheExplicitTransform(testCase)
            fa = LvdFixedAnchorCameraSettings();
            fa.fixedPosition = [2000 500 -300];
            fa.anchorFrame = testCase.kerbinFrame;   %same as the view frame
            viewFrame = testCase.kerbinFrame;

            pos = fa.getAnchorPosAtTime(123, viewFrame);
            expected = CartesianElementSet(123, [2000;500;-300], [0;0;0], testCase.kerbinFrame).convertToFrame(viewFrame).rVect;
            testCase.verifyVectorEqual(pos', expected', 1e-9);
        end

        function fixedXyzInABodyFixedFrameRotatesWithTheBody(testCase)
            %A coordinate that is fixed in the body-fixed frame sweeps out a
            %circle in the (inertial) view frame as the body rotates -- a true
            %launch-pad camera.  An inertial anchor does not move.
            rotPeriod = testCase.kerbin.rotperiod;
            testCase.assumeTrue(isfinite(rotPeriod) && rotPeriod > 0, ...
                'Body must rotate for this test to be meaningful.');

            viewFrame = testCase.kerbinFrame;                 %inertial
            bodyFixed = testCase.kerbin.getBodyFixedFrame();  %rotating

            fa = LvdFixedAnchorCameraSettings();
            fa.fixedPosition = [testCase.kerbin.radius 0 0];
            fa.anchorFrame = bodyFixed;

            tLater = rotPeriod/4;
            p0 = fa.getAnchorPosAtTime(0, viewFrame);
            pL = fa.getAnchorPosAtTime(tLater, viewFrame);

            testCase.verifyEqual(norm(pL), norm(p0), 'RelTol', 1e-9, ...
                'Rotation preserves the distance from the body centre.');
            testCase.verifyGreaterThan(norm(pL - p0), 1, ...
                'A quarter rotation must move the body-fixed anchor in the view frame.');

            %an inertial anchor at the same coordinate does NOT move
            faInertial = LvdFixedAnchorCameraSettings();
            faInertial.fixedPosition = [testCase.kerbin.radius 0 0];
            faInertial.anchorFrame = viewFrame;
            testCase.verifyVectorEqual(faInertial.getAnchorPosAtTime(tLater, viewFrame)', ...
                                       faInertial.getAnchorPosAtTime(0, viewFrame)', 1e-6, ...
                'An inertial anchor is stationary in the view frame.');
        end

        %% ------------------------------------------------- ground object

        function groundObjectAnchorResolvesToViewFrameKm(testCase)
            grdObj = testCase.makeStaticGroundObject(deg2rad(10), deg2rad(20), 5);
            viewFrame = testCase.kerbinFrame;

            fa = LvdFixedAnchorCameraSettings();
            fa.anchorType = LvdCameraAnchorTypeEnum.GroundObject;
            fa.groundObject = grdObj;

            pos = fa.getAnchorPosAtTime(0, viewFrame);
            expected = grdObj.getStateAtTime(0).convertToCartesianElementSet().convertToFrame(viewFrame).rVect;
            testCase.verifyNotEmpty(pos);
            testCase.verifyVectorEqual(pos', expected', 1e-9);
            %a ground point sits at ~ (body radius + altitude) from the centre
            testCase.verifyEqual(norm(pos), testCase.kerbin.radius + 5, 'RelTol', 1e-6);
        end

        function groundObjectAnchorIsEmptyOutsideItsWaypointRange(testCase)
            %A two-waypoint object that does not extrapolate or loop has no
            %state before/after its schedule, so getStateAtTime returns empty
            %and the anchor degrades to [].
            frame = testCase.kerbin.getBodyFixedFrame();
            wayPts = LaunchVehicleGroundObjectWayPt.empty(1,0);
            wayPts(1) = LaunchVehicleGroundObjectWayPt(GeographicElementSet(0, deg2rad(0), deg2rad(0), 0, 0,0,0, frame), 100);
            wayPts(2) = LaunchVehicleGroundObjectWayPt(GeographicElementSet(0, deg2rad(10), deg2rad(0), 0, 0,0,0, frame), 100);
            grdObj = LaunchVehicleGroundObject('Range', "", 0, wayPts);
            grdObj.extrapolateTimes = false;
            grdObj.loopWayPts = false;

            fa = LvdFixedAnchorCameraSettings();
            fa.anchorType = LvdCameraAnchorTypeEnum.GroundObject;
            fa.groundObject = grdObj;

            testCase.assumeEmpty(grdObj.getStateAtTime(1e6), ...
                'Fixture broken: the ground object was expected to have no state at t = 1e6.');
            testCase.verifyEmpty(fa.getAnchorPosAtTime(1e6, testCase.kerbinFrame), ...
                'A time outside the waypoint range yields no anchor.');
        end

        function emptyOrOrphanedGroundObjectDegradesToEmpty(testCase)
            fa = LvdFixedAnchorCameraSettings();
            fa.anchorType = LvdCameraAnchorTypeEnum.GroundObject;
            %no ground object set
            testCase.verifyEmpty(fa.getAnchorPosAtTime(0, testCase.kerbinFrame));
        end

        %% ----------------------------------------------- geometric point

        function geometricPointAnchorResolvesToViewFrameKm(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            viewFrame = testCase.kerbinFrame;
            pt = FixedPointInFrame([600 -100 250], testCase.kerbinFrame, 'Pad Point', lvdData);
            testCase.verifyFalse(pt.isVehDependent(), 'Fixture point must be vehicle-independent.');

            fa = LvdFixedAnchorCameraSettings();
            fa.anchorType = LvdCameraAnchorTypeEnum.GeometricPoint;
            fa.geometricPoint = pt;

            pos = fa.getAnchorPosAtTime(42, viewFrame);
            expected = pt.getPositionAtTime(42, [], viewFrame).rVect;
            testCase.verifyNotEmpty(pos);
            testCase.verifyVectorEqual(pos', expected', 1e-9);
        end

        function emptyGeometricPointDegradesToEmpty(testCase)
            fa = LvdFixedAnchorCameraSettings();
            fa.anchorType = LvdCameraAnchorTypeEnum.GeometricPoint;
            testCase.verifyEmpty(fa.getAnchorPosAtTime(0, testCase.kerbinFrame));
        end

        %% -------------------------------------------------- getPose glue

        function getPoseSitsAtTheAnchorAndTracksTheVehicle(testCase)
            fa = LvdFixedAnchorCameraSettings();
            fa.fixedPosition = [1000 0 0];
            fa.viewAngleDeg = 12;
            viewFrame = testCase.kerbinFrame;
            vehPos = [1000; 500; 200];

            pose = fa.getPose(0, viewFrame, vehPos);
            testCase.verifyVectorEqual(pose.position, [1000 0 0], 1e-9, 'Camera at the anchor');
            testCase.verifyVectorEqual(pose.target, vehPos', 1e-9, 'Target on the vehicle');
            testCase.verifyEqual(pose.viewAngle, 12);
        end

        function getPoseIsEmptyWhenTheAnchorOrVehicleIsUnknown(testCase)
            viewFrame = testCase.kerbinFrame;

            %unknown vehicle
            fa = LvdFixedAnchorCameraSettings();
            fa.fixedPosition = [10 0 0];
            testCase.verifyEmpty(fa.getPose(0, viewFrame, [NaN;NaN;NaN]));

            %unknown anchor (orphaned ground object)
            fa2 = LvdFixedAnchorCameraSettings();
            fa2.anchorType = LvdCameraAnchorTypeEnum.GroundObject;
            testCase.verifyEmpty(fa2.getPose(0, viewFrame, [1;2;3]));
        end

        %% ------------------------------------------ set-from-camera / io

        function setFixedPositionFromCameraRoundTrips(testCase)
            hFig = figure('Visible', 'off');
            cleanup = onCleanup(@() delete(hFig)); %#ok<NASGU>
            hAx = axes(hFig);
            hAx.CameraPosition = [3000 -1500 900];
            viewFrame = testCase.kerbinFrame;

            fa = LvdFixedAnchorCameraSettings();
            fa.anchorType = LvdCameraAnchorTypeEnum.GroundObject;   %should flip to FixedXYZ
            fa.anchorFrame = viewFrame;
            fa.setFixedPositionFromCamera(hAx, 0, viewFrame);

            testCase.verifyEqual(fa.anchorType, LvdCameraAnchorTypeEnum.FixedXYZ, ...
                'Grabbing the current camera makes the anchor a fixed coordinate.');
            %the anchor now resolves back to exactly the camera position
            testCase.verifyVectorEqual(fa.getAnchorPosAtTime(0, viewFrame)', [3000 -1500 900], 1e-6);
        end

        function loadobjUpgradesAStruct(testCase)
            s = struct('anchorType', LvdCameraAnchorTypeEnum.FixedXYZ, ...
                       'fixedPosition', [7 8 9], 'viewAngleDeg', 22);
            out = LvdFixedAnchorCameraSettings.loadobj(s);
            testCase.verifyClass(out, 'LvdFixedAnchorCameraSettings');
            testCase.verifyEqual(out.fixedPosition, [7 8 9]);
            testCase.verifyEqual(out.viewAngleDeg, 22);
        end

        function summaryStringDescribesEachAnchor(testCase)
            fa = LvdFixedAnchorCameraSettings();
            fa.fixedPosition = [1 2 3];
            testCase.verifySubstring(fa.getSummaryStr(), 'Fixed at');

            fa.anchorType = LvdCameraAnchorTypeEnum.GroundObject;
            testCase.verifySubstring(fa.getSummaryStr(), 'Ground Object');

            fa.anchorType = LvdCameraAnchorTypeEnum.GeometricPoint;
            testCase.verifySubstring(fa.getSummaryStr(), 'Geometric Point');
        end
    end

    methods(Access = private)
        function grdObj = makeStaticGroundObject(testCase, lat, long, altKm)
            %makeStaticGroundObject A single-waypoint (stationary) ground
            %object on the test body.
            frame = testCase.kerbin.getBodyFixedFrame();
            wayPt = LaunchVehicleGroundObjectWayPt(GeographicElementSet(0, lat, long, altKm, 0,0,0, frame), 100);
            grdObj = LaunchVehicleGroundObject('Static', "", 0, wayPt);
        end
    end
end
