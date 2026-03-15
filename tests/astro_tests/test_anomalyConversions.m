function tests = test_anomalyConversions
% test_anomalyConversions Tests for anomaly conversion functions
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
% Add path to the function being tested
addpath('../');
end

function testMeanToTrueElliptic(testCase)
e = 0.5;
E = pi/4;
M = E - e*sin(E);
trueAnom = computeTrueAnomFromMean(M, e);

% E to true anomaly: tan(nu/2) = sqrt((1+e)/(1-e)) * tan(E/2)
expected_true = 2 * atan(sqrt((1+e)/(1-e)) * tan(E/2));
verifyEqual(testCase, trueAnom, expected_true, 'AbsTol', 1e-12);
end

function testTrueToMeanElliptic(testCase)
e = 0.3;
trueAnom = pi/6;
M = computeMeanFromTrueAnom(trueAnom, e);

% true to E: tan(E/2) = sqrt((1-e)/(1+e)) * tan(nu/2)
E = 2 * atan(sqrt((1-e)/(1+e)) * tan(trueAnom/2));
expected_M = E - e*sin(E);
verifyEqual(testCase, M, expected_M, 'AbsTol', 1e-12);
end

function testMeanToTrueHyperbolic(testCase)
e = 1.5;
H = 0.8;
M = e*sinh(H) - H;
trueAnom = computeTrueAnomFromMean(M, e);

% H to true anomaly: tan(nu/2) = sqrt((e+1)/(e-1)) * tanh(H/2)
expected_true = 2 * atan(sqrt((e+1)/(e-1)) * tanh(H/2));
verifyEqual(testCase, trueAnom, expected_true, 'AbsTol', 1e-12);
end

function testTrueToMeanHyperbolic(testCase)
e = 2.0;
trueAnom = pi/4;
M = computeMeanFromTrueAnom(trueAnom, e);

% true to H: tanh(H/2) = sqrt((e-1)/(e+1)) * tan(nu/2)
H = 2 * atanh(sqrt((e-1)/(e+1)) * tan(trueAnom/2));
expected_M = e*sinh(H) - H;
verifyEqual(testCase, M, expected_M, 'AbsTol', 1e-12);
end
