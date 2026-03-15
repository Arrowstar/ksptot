function tests = test_getKeplerFromState
% test_getKeplerFromState Tests for getKeplerFromState.m
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
% Add path to the function being tested
addpath('../');
% Suppress a warning from a dependency
warning('off', 'MATLAB:inpolygon:ModelingWorldLower');
end

function testProgradeCircularEquatorial(testCase)
mu = 398600.4418;
r = [7000; 0; 0];
v = [0; sqrt(mu/7000); 0];

[sma, ecc, inc, raan, arg, tru] = getKeplerFromState(r, v, mu);

verifyEqual(testCase, sma, 7000, 'AbsTol', 1e-6);
verifyEqual(testCase, ecc, 0, 'AbsTol', 1e-8);
verifyEqual(testCase, inc, 0, 'AbsTol', 1e-8);
% RAAN and Arg are undefined for circular equatorial, but should be stable
verifyEqual(testCase, tru, 0, 'AbsTol', 1e-8);
end

function testRetrogradeCircularEquatorial(testCase)
mu = 398600.4418;
r = [7000; 0; 0];
v = [0; -sqrt(mu/7000); 0];

[sma, ecc, inc, raan, arg, tru] = getKeplerFromState(r, v, mu);

verifyEqual(testCase, sma, 7000, 'AbsTol', 1e-6);
verifyEqual(testCase, ecc, 0, 'AbsTol', 1e-8);
verifyEqual(testCase, inc, pi, 'AbsTol', 1e-8);
end

function testEllipticInclined(testCase)
% Example from Vallado, Fundamentals of Astrodynamics and Applications
mu = 398600.4415;
r = [6524.834; 6862.875; 6448.296];
v = [4.901327; 5.533756; -1.976309];

[sma, ecc, inc, raan, arg, tru] = getKeplerFromState(r, v, mu);

% Expected values verified by getKeplerFromState's own internal consistency check
verifyEqual(testCase, sma, 36127.343, 'RelTol', 1e-4);
verifyEqual(testCase, ecc, 0.83285, 'RelTol', 1e-4);
verifyEqual(testCase, inc, 1.5336, 'AbsTol', 1e-4);
verifyEqual(testCase, raan, 3.9776, 'AbsTol', 1e-4);
verifyEqual(testCase, arg, 0.9317, 'AbsTol', 1e-4);
verifyEqual(testCase, tru, 1.6116, 'AbsTol', 1e-4);
end

function testHyperbolic(testCase)
mu = 398600.4418;
% Escaping Earth
r = [7000; 0; 0];
v = [0; sqrt(2*mu/7000 + 10); 0]; % Speed > escape speed

[sma, ecc, inc, raan, arg, tru] = getKeplerFromState(r, v, mu);

verifyTrue(testCase, ecc > 1.0);
verifyTrue(testCase, sma < 0);
end

function teardownOnce(testCase)
warning('on', 'MATLAB:inpolygon:ModelingWorldLower');
end
