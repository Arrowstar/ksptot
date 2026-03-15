classdef testLvdGroundObjects < matlab.unittest.TestCase
    % testLvdGroundObjects Unit tests for LVD Ground Objects and GeographicElementSet
    
    properties
        LvdData
        BaseBodyInfo
        BodyFixedFrame
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            % Load an example to get valid lvdData
            examplePath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'examples', 'LaunchVehicleDesigner', 'lvdExample_ElecPowerExample.mat');
            data = load(examplePath);
            testCase.LvdData = data.lvdData;
            
            % Setup body and frame
            testCase.BaseBodyInfo = testCase.LvdData.celBodyData.getTopLevelBody();
            testCase.BodyFixedFrame = testCase.BaseBodyInfo.getBodyFixedFrame();
        end
    end
    
    methods(Test)
        function testGeographicToCartesian(testCase)
            % Test conversion of GeographicElementSet to CartesianElementSet
            body = testCase.BaseBodyInfo;
            frame = testCase.BodyFixedFrame;
            
            % Set a known point: Lat 45, Long 90, Alt 100
            lat = deg2rad(45);
            long = deg2rad(90);
            alt = 100;
            
            % Velocity Az 0 (North), El 0 (Horizontal), Mag 1 km/s
            velAz = 0;
            velEl = 0;
            velMag = 1;
            
            geo = GeographicElementSet(0, lat, long, alt, velAz, velEl, velMag, frame);
            cart = geo.convertToCartesianElementSet();
            
            % Expected position
            r_mag = body.radius + alt;
            expected_x = r_mag * cos(lat) * cos(long);
            expected_y = r_mag * cos(lat) * sin(long);
            expected_z = r_mag * sin(lat);
            
            testCase.verifyEqual(cart.rVect(1), expected_x, 'AbsTol', 1e-8);
            testCase.verifyEqual(cart.rVect(2), expected_y, 'AbsTol', 1e-8);
            testCase.verifyEqual(cart.rVect(3), expected_z, 'AbsTol', 1e-8);
            
            % Expected velocity direction (North)
            % North at (lat, long) is [-sin(lat)*cos(long); -sin(lat)*sin(long); cos(lat)]
            e_n = [-sin(lat)*cos(long); -sin(lat)*sin(long); cos(lat)];
            expected_v = e_n * velMag;
            
            testCase.verifyEqual(cart.vVect, expected_v, 'AbsTol', 1e-8);
        end

        function testSingleWaypoint(testCase)
            frame = testCase.BodyFixedFrame;
            elem = GeographicElementSet(0, deg2rad(10), deg2rad(20), 5, 0, 0, 0, frame);
            wpt = LaunchVehicleGroundObjectWayPt(elem, 1000);
            
            grdObj = LaunchVehicleGroundObject('Single', '', 0, wpt);
            
            % Should always return the same state regardless of time
            state1 = grdObj.getStateAtTime(500);
            state2 = grdObj.getStateAtTime(2000);
            
            testCase.verifyEqual(state1.lat, deg2rad(10), 'AbsTol', 1e-12);
            testCase.verifyEqual(state2.lat, deg2rad(10), 'AbsTol', 1e-12);
        end
        
        function testGroundObjectInterpolation(testCase)
            % Test basic interpolation between waypoints
            frame = testCase.BodyFixedFrame;
            
            % Waypoint 1: Equator, Prime Meridian, 10km alt
            elem1 = GeographicElementSet(0, 0, 0, 10, 0, 0, 0, frame);
            wpt1 = LaunchVehicleGroundObjectWayPt(elem1, 1000); % 1000s duration
            
            % Waypoint 2: Equator, 90 deg East, 20km alt
            elem2 = GeographicElementSet(1000, 0, deg2rad(90), 20, 0, 0, 0, frame);
            wpt2 = LaunchVehicleGroundObjectWayPt(elem2, 1000);
            
            grdObj = LaunchVehicleGroundObject('TestObj', '', 0, [wpt1, wpt2]);
            grdObj.loopWayPts = true;
            
            % Test at time = 500s (Halfway)
            state = grdObj.getStateAtTime(500);
            
            % Expected: 45 deg East, 15km alt
            testCase.verifyEqual(state.lat, 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(state.long, deg2rad(45), 'AbsTol', 1e-12);
            testCase.verifyEqual(state.alt, 15, 'AbsTol', 1e-12);
        end
        
        function testGroundObjectLooping(testCase)
            % Test looping behavior (WayPt 2 -> WayPt 1)
            frame = testCase.BodyFixedFrame;
            
            % Waypoint 1: Lat 0, Long 0
            elem1 = GeographicElementSet(0, 0, 0, 0, 0, 0, 0, frame);
            wpt1 = LaunchVehicleGroundObjectWayPt(elem1, 1000);
            
            % Waypoint 2: Lat 10, Long 0
            elem2 = GeographicElementSet(1000, deg2rad(10), 0, 0, 0, 0, 0, frame);
            wpt2 = LaunchVehicleGroundObjectWayPt(elem2, 2000); % 2000s back to wpt1
            
            grdObj = LaunchVehicleGroundObject('TestObj', '', 0, [wpt1, wpt2]);
            grdObj.loopWayPts = true;
            grdObj.extrapolateTimes = true;
            
            % Total period = 3000s
            % Test at 2000s (Halfway between Wpt2 and Wpt1)
            state = grdObj.getStateAtTime(2000);
            
            % Expected: Lat 5, Long 0
            testCase.verifyEqual(state.lat, deg2rad(5), 'AbsTol', 1e-12);
            testCase.verifyEqual(state.long, 0, 'AbsTol', 1e-12);
            
            % Test at 4000s (Should be same as 1000s: WayPt 2)
            state2 = grdObj.getStateAtTime(4000);
            testCase.verifyEqual(state2.lat, deg2rad(10), 'AbsTol', 1e-12);
        end
        
        function testGroundObjectPingPong(testCase)
            % Test ping-pong behavior (1->2->1) when looping is false
            frame = testCase.BodyFixedFrame;
            
            elem1 = GeographicElementSet(0, 0, 0, 0, 0, 0, 0, frame);
            wpt1 = LaunchVehicleGroundObjectWayPt(elem1, 1000);
            
            elem2 = GeographicElementSet(1000, deg2rad(10), 0, 0, 0, 0, 0, frame);
            wpt2 = LaunchVehicleGroundObjectWayPt(elem2, 1000);
            
            grdObj = LaunchVehicleGroundObject('TestObj', '', 0, [wpt1, wpt2]);
            grdObj.loopWayPts = false;
            grdObj.extrapolateTimes = true;
            
            % Period = 1000 + 1000 = 2000s (Wpt 1->2 and then 2->1)
            % Test at 1500s (Halfway back from Wpt2 to Wpt1)
            state = grdObj.getStateAtTime(1500);
            
            testCase.verifyEqual(state.lat, deg2rad(5), 'AbsTol', 1e-12);
            testCase.verifyEqual(state.long, 0, 'AbsTol', 1e-12);
        end

        function testGroundObjectExtrapolationFalse(testCase)
            frame = testCase.BodyFixedFrame;
            elem1 = GeographicElementSet(0, 0, 0, 0, 0, 0, 0, frame);
            wpt1 = LaunchVehicleGroundObjectWayPt(elem1, 1000);
            elem2 = GeographicElementSet(1000, deg2rad(10), 0, 0, 0, 0, 0, frame);
            wpt2 = LaunchVehicleGroundObjectWayPt(elem2, 1000);
            
            grdObj = LaunchVehicleGroundObject('NoExtrap', '', 100, [wpt1, wpt2]);
            grdObj.loopWayPts = false;
            grdObj.extrapolateTimes = false;
            
            % Total duration = 2000s starting at T=100
            % Test at T=50 (outside)
            state = grdObj.getStateAtTime(50);
            testCase.verifyEmpty(state);
            
            % Test at T=2200 (outside)
            state = grdObj.getStateAtTime(2200);
            testCase.verifyEmpty(state);
            
            % Test at T=1100 (inside)
            state = grdObj.getStateAtTime(1100);
            testCase.verifyNotEmpty(state);
            testCase.verifyEqual(state.lat, deg2rad(10), 'AbsTol', 1e-12);
        end
    end
end
