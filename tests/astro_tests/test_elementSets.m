classdef test_elementSets < matlab.unittest.TestCase
    % test_elementSets Tests for element set classes and conversions
    
    properties
        bodyInfo
        frame
        mu = 398600.4415;
        radius = 6378.137;
    end
    
    methods(TestClassSetup)
        function setupEnvironment(testCase)
            % Create a mock body and frame for testing
            body = KSPTOT_BodyInfo();
            body.name = 'TestBody';
            body.gm = testCase.mu;
            body.radius = testCase.radius;
            body.rotperiod = 86400; % 24 hours
            body.rotini = 0;
            
            testCase.bodyInfo = body;
            testCase.frame = body.getBodyCenteredInertialFrame();
            
            % Add path to ensure classes are visible if needed
            % (Assuming they are already on path in the KSPTOT environment)
        end
    end
    
    methods(Test)
        function testCartesianToKeplerian(testCase)
            % Test conversion from Cartesian to Keplerian
            ut = 0;
            rVect = [7000; 0; 0];
            vVect = [0; sqrt(testCase.mu/7000); 0];
            
            cart = CartesianElementSet(ut, rVect, vVect, testCase.frame);
            kep = cart.convertToKeplerianElementSet();
            
            testCase.verifyClass(kep, 'KeplerianElementSet');
            testCase.verifyEqual(kep.sma, 7000, 'RelTol', 1e-10);
            testCase.verifyEqual(kep.ecc, 0, 'AbsTol', 1e-10);
            testCase.verifyEqual(kep.inc, 0, 'AbsTol', 1e-10);
        end
        
        function testKeplerianToCartesian(testCase)
            % Test conversion from Keplerian to Cartesian
            ut = 0;
            sma = 10000;
            ecc = 0.1;
            inc = deg2rad(28.5);
            raan = deg2rad(45);
            arg = deg2rad(30);
            tru = deg2rad(60);
            
            kep = KeplerianElementSet(ut, sma, ecc, inc, raan, arg, tru, testCase.frame);
            cart = kep.convertToCartesianElementSet();
            
            testCase.verifyClass(cart, 'CartesianElementSet');
            
            % Verify math using procedural function
            [rExp, vExp] = getStatefromKepler(sma, ecc, inc, raan, arg, tru, testCase.mu);
            testCase.verifyEqual(cart.rVect, rExp, 'RelTol', 1e-10);
            testCase.verifyEqual(cart.vVect, vExp, 'RelTol', 1e-10);
        end
        
        function testGeographicToCartesian(testCase)
            % Test conversion from Geographic to Cartesian
            ut = 0;
            lat = deg2rad(45);
            long = deg2rad(90);
            alt = 500;
            velAz = deg2rad(90); % Eastward
            velEl = 0;
            velMag = 7.5;
            
            geo = GeographicElementSet(ut, lat, long, alt, velAz, velEl, velMag, testCase.frame);
            cart = geo.convertToCartesianElementSet();
            
            % Expected position
            r = testCase.radius + alt;
            xExp = 0; % cos(45)*cos(90) = 0
            yExp = r * cos(lat);
            zExp = r * sin(lat);
            
            testCase.verifyEqual(cart.rVect, [xExp; yExp; zExp], 'AbsTol', 1e-8);
        end
        
        function testUniversalToKeplerian(testCase)
            % Test conversion from Universal to Keplerian
            ut = 0;
            sma = 8000;
            ecc = 0.2;
            c3 = -testCase.mu / sma;
            rP = sma * (1 - ecc);
            inc = 0.1;
            raan = 0.2;
            arg = 0.3;
            tau = 0; % At periapsis
            
            univ = UniversalElementSet(ut, c3, rP, inc, raan, arg, tau, testCase.frame);
            kep = univ.convertToKeplerianElementSet();
            
            testCase.verifyEqual(kep.sma, sma, 'RelTol', 1e-10);
            testCase.verifyEqual(kep.ecc, ecc, 'RelTol', 1e-10);
            testCase.verifyEqual(kep.tru, 0, 'AbsTol', 1e-10);
        end
        
        function testRoundTripCartKep(testCase)
            % Cartesian -> Keplerian -> Cartesian
            ut = 1234.567;
            rVect = [5000; 6000; 2000];
            vVect = [-4; 5; 2];
            
            cart1 = CartesianElementSet(ut, rVect, vVect, testCase.frame);
            kep = cart1.convertToKeplerianElementSet();
            cart2 = kep.convertToCartesianElementSet();
            
            testCase.verifyEqual(cart2.rVect, cart1.rVect, 'RelTol', 1e-10);
            testCase.verifyEqual(cart2.vVect, cart1.vVect, 'RelTol', 1e-10);
            testCase.verifyEqual(cart2.time, cart1.time);
        end
        
        function testCircularEquatorialEdgeCase(testCase)
            % Test case where node and periapsis are undefined (e=0, i=0)
            ut = 0;
            sma = 7000;
            ecc = 0;
            inc = 0;
            raan = 0;
            arg = 0;
            tru = deg2rad(90);
            
            kep = KeplerianElementSet(ut, sma, ecc, inc, raan, arg, tru, testCase.frame);
            cart = kep.convertToCartesianElementSet();
            
            % Should be at [0; 7000; 0] if node/peri are 0
            testCase.verifyEqual(cart.rVect, [0; 7000; 0], 'AbsTol', 1e-10);
            
            % Convert back
            kep2 = cart.convertToKeplerianElementSet();
            testCase.verifyEqual(kep2.sma, sma, 'RelTol', 1e-10);
            testCase.verifyEqual(kep2.ecc, 0, 'AbsTol', 1e-10);
            testCase.verifyEqual(kep2.inc, 0, 'AbsTol', 1e-10);
        end
        
        function testParabolicEdgeCase(testCase)
            % Test parabolic orbit (e=1)
            % Universal handled e=1 via large SMA approximation.
            ut = 0;
            rP = 7000;
            c3 = 0; % Parabolic
            inc = 0.5;
            raan = 0.6;
            arg = 0.7;
            tau = 1000; % 1000 seconds past periapsis
            
            univ = UniversalElementSet(ut, c3, rP, inc, raan, arg, tau, testCase.frame);
            cart = univ.convertToCartesianElementSet();
            
            % Check that it's finite and not NaN
            testCase.verifyTrue(all(isfinite(cart.rVect)));
            testCase.verifyTrue(all(isfinite(cart.vVect)));
            
            % Verify velocity at periapsis if tau was 0
            % vP = sqrt(2*mu/rP)
            univ0 = UniversalElementSet(ut, c3, rP, inc, raan, arg, 0, testCase.frame);
            cart0 = univ0.convertToCartesianElementSet();
            vP_mag = sqrt(2 * testCase.mu / rP);
            % Tolerance adjusted for large SMA approximation (1e12)
            testCase.verifyEqual(norm(cart0.vVect), vP_mag, 'RelTol', 1e-8);
        end
        
        function testGeographicToUniversal(testCase)
            % Geographic -> Universal
            ut = 0;
            lat = deg2rad(-10);
            long = deg2rad(200);
            alt = 300;
            velAz = deg2rad(45);
            velEl = deg2rad(10);
            velMag = 8.0;
            
            geo = GeographicElementSet(ut, lat, long, alt, velAz, velEl, velMag, testCase.frame);
            univ = geo.convertToUniversalElementSet();
            
            testCase.verifyClass(univ, 'UniversalElementSet');
            
            % Round trip back to Geographic
            geo2 = univ.convertToGeographicElementSet();
            testCase.verifyEqual(geo2.lat, geo.lat, 'RelTol', 1e-10);
            testCase.verifyEqual(geo2.long, geo.long, 'RelTol', 1e-10);
            testCase.verifyEqual(geo2.alt, geo.alt, 'RelTol', 1e-10);
        end
        
        function testKeplerianToGeographic(testCase)
            % Keplerian -> Geographic
            ut = 500;
            sma = 7500;
            ecc = 0.05;
            inc = deg2rad(98);
            raan = deg2rad(180);
            arg = deg2rad(270);
            tru = deg2rad(0);
            
            kep = KeplerianElementSet(ut, sma, ecc, inc, raan, arg, tru, testCase.frame);
            geo = kep.convertToGeographicElementSet();
            
            testCase.verifyClass(geo, 'GeographicElementSet');
            testCase.verifyEqual(geo.alt, sma*(1-ecc) - testCase.radius, 'RelTol', 1e-10);
        end

        function testUniversalToGeographic(testCase)
            % Universal -> Geographic
            ut = 0;
            c3 = -20;
            rP = 7000;
            inc = 1.0;
            raan = 2.0;
            arg = 3.0;
            tau = 100;
            
            univ = UniversalElementSet(ut, c3, rP, inc, raan, arg, tau, testCase.frame);
            geo = univ.convertToGeographicElementSet();
            
            testCase.verifyClass(geo, 'GeographicElementSet');
        end

        
        function testRetrogradeEquatorial(testCase)
            % Regression test for i=180 deg bug
            % Orientation must depend on raan - arg (or similar Euler logic)
            ut = 0;
            sma = 10000;
            ecc = 0.5;
            inc = pi;
            raan = deg2rad(30);
            arg = deg2rad(60);
            tru = 0;
            
            kep = KeplerianElementSet(ut, sma, ecc, inc, raan, arg, tru, testCase.frame);
            cart = kep.convertToCartesianElementSet();
            
            % Expected position: [5000 * cos(30-60); 5000 * sin(30-60); 0]
            % which is [5000 * cos(-30); 5000 * sin(-30); 0] = [4330.127; -2500; 0]
            expected_r = [4330.12701892219; -2500; 0];
            testCase.verifyEqual(cart.rVect, expected_r, 'AbsTol', 1e-10);
            
            % Round trip
            kep2 = cart.convertToKeplerianElementSet();
            % Conversion back should normalize raan to 0
            testCase.verifyEqual(kep2.inc, pi, 'AbsTol', 1e-10);
            testCase.verifyEqual(kep2.raan, 0, 'AbsTol', 1e-10);
            % longPeri = raan - arg = 30 - 60 = -30 = 330 deg?
            % Actually getKeplerFromState_Alg calculates longPeri as atan2(ey, ex)
            % ECI-X = cos(30-60), ECI-Y = sin(30-60)
            % So longPeri = -30 deg = 330 deg = 5.75958... rad
            testCase.verifyEqual(kep2.arg, AngleZero2Pi(raan - arg), 'RelTol', 1e-10);
        end
        
        function testVectorization(testCase)
            % Test that methods work on arrays of objects
            ut = [0, 100, 200];
            rVects = [[7000;0;0], [7100;0;0], [7200;0;0]];
            vVects = [[0;7.5;0], [0;7.4;0], [0;7.3;0]];
            
            carts = CartesianElementSet(ut, rVects, vVects, testCase.frame);
            testCase.verifyNumElements(carts, 3);
            
            keps = carts.convertToKeplerianElementSet();
            testCase.verifyNumElements(keps, 3);
            testCase.verifyEqual([keps.time], ut);
            
            % Ensure it can handle mixed prograde/retrograde if possible
            % (Though our current vectorization logic handles them well now)
            incs = [0, pi/4, pi];
            ecc = [0.1, 0.2, 0.3];
            keps2 = repmat(KeplerianElementSet.getDefaultElements(), 1, 3);
            for i=1:3
                keps2(i) = KeplerianElementSet(0, 10000, ecc(i), incs(i), 0.1, 0.2, 0.3, testCase.frame);
            end
            
            carts2 = keps2.convertToCartesianElementSet();
            testCase.verifyNumElements(carts2, 3);
        end
    end
end
