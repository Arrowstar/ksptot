function tests = test_computeApogeePerigee
% test_computeApogeePerigee Tests for computeApogeePerigee.m
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
% Add path to the function being tested
addpath('../');
end

function testBasicFunctionality(testCase)
% Test with typical values for an elliptical orbit
sma = 10000; % km
ecc = 0.2;
expected_rAp = 12000;
expected_rPe = 8000;

[rAp, rPe] = computeApogeePerigee(sma, ecc);

verifyEqual(testCase, rAp, expected_rAp, 'Apogee calculation is incorrect.');
verifyEqual(testCase, rPe, expected_rPe, 'Perigee calculation is incorrect.');
end

function testVectorInput(testCase)
% Test with vector inputs
sma = [10000, 20000];
ecc = [0.2, 0.5];
expected_rAp = [12000, 30000];
expected_rPe = [8000, 10000];

[rAp, rPe] = computeApogeePerigee(sma, ecc);

verifyEqual(testCase, rAp, expected_rAp, 'Apogee calculation for vector input is incorrect.');
verifyEqual(testCase, rPe, expected_rPe, 'Perigee calculation for vector input is incorrect.');
end

function testCircularOrbit(testCase)
% Test a circular orbit where eccentricity is 0
sma = 10000;
ecc = 0;
expected_rAp = 10000;
expected_rPe = 10000;

[rAp, rPe] = computeApogeePerigee(sma, ecc);

verifyEqual(testCase, rAp, expected_rAp, 'Apogee for circular orbit is incorrect.');
verifyEqual(testCase, rPe, expected_rPe, 'Perigee for circular orbit is incorrect.');
end

function testParabolicOrbit(testCase)
% Test a parabolic orbit where eccentricity is 1
sma = 10000; % For a parabola, sma is infinite, but the formula should still work
ecc = 1;
expected_rAp = 20000;
expected_rPe = 0;

[rAp, rPe] = computeApogeePerigee(sma, ecc);

verifyEqual(testCase, rAp, expected_rAp, 'Apogee for parabolic orbit is incorrect.');
verifyEqual(testCase, rPe, expected_rPe, 'Perigee for parabolic orbit is incorrect.');
end

function testHyperbolicOrbit(testCase)
% Test a hyperbolic orbit where eccentricity is > 1
sma = -20900; % For a hyperbola, sma is negative.
ecc = 1.25;
expected_rAp = -20900 * (1 + 1.25); % this is a non-physical value, but mathematically correct
expected_rPe = -20900 * (1 - 1.25);

[rAp, rPe] = computeApogeePerigee(sma, ecc);

verifyEqual(testCase, rAp, expected_rAp, 'Apogee for hyperbolic orbit is incorrect.');
verifyEqual(testCase, rPe, expected_rPe, 'Perigee for hyperbolic orbit is incorrect.');
end
