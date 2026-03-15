function tests = test_solveKepler
% test_solveKepler Tests for solveKepler.m
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
% Add path to the function being tested
addpath('../');
end

function testCircular(testCase)
% For e=0, M=E
e = 0;
M = pi/4;
E = solveKepler(M, e);
verifyEqual(testCase, E, M, 'AbsTol', 1e-12);
end

function testElliptic(testCase)
% M = E - e*sin(E)
e = 0.5;
E_expected = pi/3;
M = E_expected - e*sin(E_expected);
E_actual = solveKepler(M, e);
verifyEqual(testCase, E_actual, E_expected, 'AbsTol', 1e-12);
end

function testEllipticPerigee(testCase)
e = 0.5;
M = 0;
E = solveKepler(M, e);
verifyEqual(testCase, E, 0, 'AbsTol', 1e-12);
end

function testEllipticApogee(testCase)
e = 0.5;
M = pi;
E = solveKepler(M, e);
verifyEqual(testCase, E, pi, 'AbsTol', 1e-12);
end

function testHyperbolic(testCase)
% M = e*sinh(H) - H (hyperbolic Kepler's Eq)
e = 1.5;
H_expected = 1.0;
M = e*sinh(H_expected) - H_expected;
H_actual = solveKepler(M, e);
verifyEqual(testCase, H_actual, H_expected, 'AbsTol', 1e-12);
end

function testLargeMeanAnomaly(testCase)
% Test if it handles M > 2*pi for elliptic orbits
e = 0.5;
E_expected = pi/3;
M = E_expected - e*sin(E_expected) + 2*pi;
E_actual = solveKepler(M, e);
% solveKepler might return E in 0-2pi range
verifyEqual(testCase, AngleZero2Pi(E_actual), AngleZero2Pi(E_expected), 'AbsTol', 1e-12);
end
