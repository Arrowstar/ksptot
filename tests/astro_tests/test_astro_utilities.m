function tests = test_astro_utilities
% test_astro_utilities Tests for lambertBattinVector.m and rodrigues_rot.m
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
% Add path to the functions being tested
addpath('../');
end

function testLambertEarthMars(testCase)
% A known case (approximate)
mu = 1.32712440018e11; % Sun GM in km^3/s^2
r1 = [1.4710e8; 0; 0]'; % Earth perihelion approx
r2 = [0; 2.2794e8; 0]'; % Mars approx
dt = 200 * 24 * 3600; % 200 days in seconds

[v1, v2] = orbit.lambert(r1, r2, dt/86400, 0, mu);

% Check consistency: r1, v1 at t=0 should lead to r2, v2 at t=dt
[sma, ecc, inc, raan, arg, tru1] = getKeplerFromState(r1, v1, mu);

M1 = computeMeanFromTrueAnom(tru1, ecc);
n = sqrt(mu/abs(sma)^3);
M2 = M1 + n * dt;
tru2_expected = computeTrueAnomFromMean(M2, ecc);

[r2_check, v2_check] = getStatefromKepler(sma, ecc, inc, raan, arg, tru2_expected, mu);

% Check that the orbit found by Lambert actually hits r2 at t=dt
% Use norm of difference for robustness against near-zero components
diff_r = norm(r2_check(:)' - r2);
diff_v = norm(v2_check(:)' - v2);

verifyLessThan(testCase, diff_r, 1E-6, 'Position vector mismatch after Lambert solver.');
verifyLessThan(testCase, diff_v, 1e-2, 'Velocity vector mismatch after Lambert solver.');
end

function testRodrigues90Deg(testCase)
v = [1; 0; 0];
axis = [0; 0; 1];
theta = pi/2;
v_rot = rodrigues_rot(v, axis, theta);
verifyEqual(testCase, v_rot, [0; 1; 0], 'AbsTol', 1e-12);
end

function testRodrigues180Deg(testCase)
v = [1; 1; 0];
axis = [0; 0; 1];
theta = pi;
v_rot = rodrigues_rot(v, axis, theta);
verifyEqual(testCase, v_rot, [-1; -1; 0], 'AbsTol', 1e-12);
end

function testRodriguesAxisRotation(testCase)
% Rotating the axis vector itself should return the axis vector
v = [1; 2; 3];
axis = v / norm(v);
theta = 1.234;
v_rot = rodrigues_rot(v, axis, theta);
verifyEqual(testCase, v_rot, v, 'AbsTol', 1e-12);
end
