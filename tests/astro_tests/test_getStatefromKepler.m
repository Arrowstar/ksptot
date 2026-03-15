function tests = test_getStatefromKepler
% test_getStatefromKepler Tests for getStatefromKepler.m
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
% Add path to the function being tested
addpath('../');
% Suppress a warning from a dependency
warning('off', 'MATLAB:inpolygon:ModelingWorldLower');
end

function testGoldenValueCurtisExample(testCase)
% Test based on Example 3.7 from "Orbital Mechanics for Engineering
% Students" by Howard D. Curtis.

mu = 398600;

% Starting state vectors from the book
r_initial = [8000; 6000; 0];
v_initial = [-3.4; 5.6; 0];

% Get the precise Keplerian elements from the state vectors
[sma, ecc, inc, raan, argp, ta] = getKeplerFromState(r_initial, v_initial, mu);

% Now, use these elements to get the state vectors back
[rVect, vVect] = getStatefromKepler(sma, ecc, inc, raan, argp, ta, mu);

% The results should be very close to the initial state vectors
verifyEqual(testCase, rVect, r_initial, 'AbsTol', 1e-9, 'Position vector does not match expected value.');
verifyEqual(testCase, vVect, v_initial, 'AbsTol', 1e-9, 'Velocity vector does not match expected value.');
end

function testCircularEquatorialOrbit(testCase)
% Test a simple circular, equatorial orbit
mu = 398600;
r = 7000; % km
v_mag = sqrt(mu/r);

sma = r;
ecc = 0;
inc = 0;
raan = 0;
argp = 0;
ta = pi/2; % 90 degrees, should be at [0, r, 0]

expected_r = [0; r; 0];
expected_v = [-v_mag; 0; 0];

[rVect, vVect] = getStatefromKepler(sma, ecc, inc, raan, argp, ta, mu);

verifyEqual(testCase, rVect, expected_r, 'AbsTol', 1e-10, 'Position vector for circular orbit is incorrect.');
verifyEqual(testCase, vVect, expected_v, 'AbsTol', 1e-10, 'Velocity vector for circular orbit is incorrect.');
end

function testKeplerToStateAndBack(testCase)
% Test the consistency by converting to state and back to Keplerian
mu = 398600;
sma1 = 13730;
ecc1 = 0.414;
inc1 = 10 * pi/180;
raan1 = 5 * pi/180;
argp1 = 23.5 * pi/180;
ta1 = 126.5 * pi/180;

[rVect, vVect] = getStatefromKepler(sma1, ecc1, inc1, raan1, argp1, ta1, mu);
[sma2, ecc2, inc2, raan2, argp2, ta2] = getKeplerFromState(rVect, vVect, mu);

verifyEqual(testCase, sma2, sma1, 'RelTol', 1e-10, 'SMA does not match after conversion.');
verifyEqual(testCase, ecc2, ecc1, 'RelTol', 1e-10, 'Eccentricity does not match after conversion.');
verifyEqual(testCase, inc2, inc1, 'RelTol', 1e-10, 'Inclination does not match after conversion.');
verifyEqual(testCase, raan2, raan1, 'RelTol', 1e-10, 'RAAN does not match after conversion.');
verifyEqual(testCase, argp2, argp1, 'RelTol', 1e-10, 'Argument of perigee does not match after conversion.');
verifyEqual(testCase, ta2, ta1, 'RelTol', 1e-10, 'True anomaly does not match after conversion.');

end

function teardownOnce(testCase)
warning('on', 'MATLAB:inpolygon:ModelingWorldLower');
end
