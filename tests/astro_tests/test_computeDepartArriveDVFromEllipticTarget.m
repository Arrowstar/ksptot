function tests = test_computeDepartArriveDVFromEllipticTarget
% test_computeDepartArriveDVFromEllipticTarget Tests for computeDepartArriveDVFromEllipticTarget.m
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
% Add path to the function being tested
addpath('../');
end

function testDepartureFromEarth(testCase)
% Test case: Departure from a 200km circular parking orbit around Earth

% Earth parameters
mu = 398600; % km^3/s^2

% Parking orbit (200km altitude circular)
r_p = 6378 + 200; % km
sma = r_p;
ecc = 0;
inc = 0; % Equatorial
raan = 0;
argp = 0;
ta = 0;

% Hyperbolic excess velocity magnitude
v_inf_mag = 3.5; % km/s

% For a purely tangential departure from perigee (at ta=0, velocity is in +y direction),
% the outgoing asymptote (V_infinity vector) is deflected by the hyperbola's turning angle.
% We compute the corresponding V_infinity vector to request a tangential departure:
hSMA = -mu / (v_inf_mag^2);
hEcc = 1 - r_p / hSMA;
theta_inf = acos(-1 / hEcc);
v_inf_vect = v_inf_mag * [cos(theta_inf), sin(theta_inf), 0]; 

[dV, dVVect, dVVectNTW, eRVect, hOrbit, hHat, ECI2TWNRotMat] = ...
    computeDepartArriveDVFromEllipticTarget(sma, ecc, inc, raan, argp, ta, mu, v_inf_vect);

% Expected values
% 1. Parking orbit velocity
v_parking = sqrt(mu / r_p);
% 2. Escape velocity at parking orbit radius
v_escape = sqrt(2 * mu / r_p);
% 3. Required velocity at perigee of hyperbola
v_perigee = sqrt(v_inf_mag^2 + v_escape^2);
% 4. Expected dV
expected_dV = v_perigee - v_parking;

fprintf('\n--- Inputs ---\n');
fprintf('sma: %.4f\n', sma);
fprintf('ecc: %.4f\n', ecc);
fprintf('inc: %.4f\n', inc);
fprintf('raan: %.4f\n', raan);
fprintf('argp: %.4f\n', argp);
fprintf('ta: %.4f\n', ta);
fprintf('mu: %.4f\n', mu);
fprintf('v_inf_vect: [%.4f, %.4f, %.4f]\n', v_inf_vect);

fprintf('\n--- Expected Values ---\n');
fprintf('v_parking: %.4f\n', v_parking);
fprintf('v_escape: %.4f\n', v_escape);
fprintf('v_perigee: %.4f\n', v_perigee);
fprintf('expected_dV: %.4f\n', expected_dV);

fprintf('\n--- Actual Values ---\n');
fprintf('dV: %.4f\n', dV);
fprintf('dVVect: [%.4f, %.4f, %.4f]\n', dVVect);
fprintf('dVVectNTW: [%.4f, %.4f, %.4f]\n', dVVectNTW);


% Verify dV magnitude
verifyEqual(testCase, dV, expected_dV, 'RelTol', 1e-5, ...
    'Incorrect dV magnitude for Earth departure.');

% Verify dV is the norm of dVVect
verifyEqual(testCase, dV, norm(dVVect), 'AbsTol', 1e-10, ...
    'dV is not the norm of dVVect.');

% Verify NTW transformation
dVVect_reconstructed = ECI2TWNRotMat * dVVectNTW;
verifyEqual(testCase, dVVect, dVVect_reconstructed, 'AbsTol', 1e-10, ...
    'NTW to ECI transformation is incorrect.');

end
