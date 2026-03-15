function tests = test_computePeriod
% test_computePeriod Tests for computePeriod.m
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
% Add path to the function being tested
addpath('../');
end

function testBasicFunctionality(testCase)
% Test with a known value for Earth's orbit around the sun
sma = 149.6e6; % km
mu = 1.327e11; % km^3/s^2 (Sun's gravitational parameter)
expected_period = 31560349.01; % seconds (approx 1 year)

actual_period = computePeriod(sma, mu);

verifyEqual(testCase, actual_period, expected_period, 'RelTol', 1e-5, ...
    'Calculated period for Earth is incorrect.');
end

function testEdgeCaseZeroSMA(testCase)
% Test with a semi-major axis of zero
sma = 0;
mu = 1.327e11;
verifyError(testCase, @() computePeriod(sma, mu), 'MATLAB:computePeriod:smaMustBePositive');
end

function testVectorInput(testCase)
% Test with a vector of sma values
sma = [149.6e6, 108.2e6]; % Earth and Venus
mu = 1.327e11;
expected_periods = [31560349.01, 19412671.17];

actual_periods = computePeriod(sma, mu);

verifyEqual(testCase, actual_periods, expected_periods, 'RelTol', 1e-5, ...
    'Calculated periods for vector input are incorrect.');
end
