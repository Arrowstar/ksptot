function catalog = ksptotTestOrbitCatalog()
% ksptotTestOrbitCatalog Canonical set of orbits used to parameterize tests.
%
% Returns a struct whose field names are valid MATLAB identifiers (so the
% struct can be used directly as a matlab.unittest TestParameter) and whose
% values are structs with fields:
%
%   rVect - 3x1 position [km]
%   vVect - 3x1 velocity [km/s]
%   gmu   - gravitational parameter [km^3/s^2]
%   desc  - human readable description
%
% The catalog deliberately includes the degenerate geometries (circular,
% equatorial, retrograde, polar) where classical element sets are singular,
% because those are exactly the cases where conversion code tends to break.

    gmuEarth  = 398600.4418;
    gmuKerbin = 3531.6;

    catalog = struct();

    % ---- Well conditioned general orbits --------------------------------
    catalog.genericLEO       = fromCoe(6878, 0.001, 51.6, 130, 45,  20, gmuEarth,  'Generic LEO, ISS-like');
    catalog.genericMEO       = fromCoe(26560, 0.01, 55.0,  60, 30, 200, gmuEarth,  'Generic MEO, GPS-like');
    catalog.eccentricGTO     = fromCoe(24396, 0.73,  7.0,  15, 178, 90, gmuEarth,  'Highly eccentric GTO');
    catalog.molniya          = fromCoe(26554, 0.74, 63.4,  90, 270, 15, gmuEarth,  'Molniya, critical inclination');
    catalog.kerbinLowOrbit   = fromCoe(  700, 0.02, 28.0,  75, 10, 300, gmuKerbin, 'Low Kerbin orbit');

    % ---- Near-degenerate: circular ---------------------------------------
    catalog.circularInclined = fromCoe(7000, 0,      45.0,  60,  0, 120, gmuEarth, 'Exactly circular, inclined');
    catalog.nearCircular     = fromCoe(7000, 1e-8,   45.0,  60, 30, 120, gmuEarth, 'Near-circular, inclined');

    % ---- Near-degenerate: equatorial -------------------------------------
    catalog.ellipEquatorial  = fromCoe(8000, 0.20,    0.0,   0, 40,  70, gmuEarth, 'Elliptical equatorial prograde');
    catalog.nearEquatorial   = fromCoe(8000, 0.20,  1e-7,   45, 40,  70, gmuEarth, 'Elliptical, 1e-7 rad inclination');

    % ---- Doubly degenerate -----------------------------------------------
    catalog.circEquatorial   = fromCoe(7000, 0,       0.0,   0,  0, 120, gmuEarth, 'Circular equatorial prograde');

    % ---- Retrograde -------------------------------------------------------
    catalog.retrogradeIncl   = fromCoe(7000, 0.10, 135.0,  60, 30, 120, gmuEarth, 'Retrograde inclined');
    catalog.circEquatRetro   = fromCoe(7000, 0,    180.0,   0,  0, 120, gmuEarth, 'Circular equatorial RETROGRADE');
    catalog.ellipEquatRetro  = fromCoe(8000, 0.20, 180.0,   0, 40,  70, gmuEarth, 'Elliptical equatorial RETROGRADE');

    % ---- Polar --------------------------------------------------------------
    catalog.polar            = fromCoe(7500, 0.05,  90.0,  60, 30, 120, gmuEarth, 'Polar orbit');

    % ---- Hyperbolic ----------------------------------------------------------
    catalog.hyperbolicLow    = fromCoe(-15000, 1.20, 30.0,  40, 25,  30, gmuEarth, 'Hyperbolic, ecc = 1.2');
    catalog.hyperbolicHigh   = fromCoe( -8000, 2.50, 30.0,  40, 25, -40, gmuEarth, 'Hyperbolic, ecc = 2.5, inbound');
    catalog.nearParabolic    = fromCoe(-2.0e6, 1.0001, 30.0, 40, 25, 10, gmuEarth, 'Near-parabolic, ecc = 1.0001');
end

function s = fromCoe(sma, ecc, incDeg, raanDeg, argDeg, truDeg, gmu, desc)
%fromCoe Builds a catalog entry from classical elements via the oracle.

    [rVect, vVect] = refCoe2Rv(sma, ecc, deg2rad(incDeg), deg2rad(raanDeg), ...
                               deg2rad(argDeg), deg2rad(truDeg), gmu);

    s = struct('rVect', rVect, 'vVect', vVect, 'gmu', gmu, 'desc', desc, ...
               'sma', sma, 'ecc', ecc, 'inc', deg2rad(incDeg), ...
               'raan', deg2rad(raanDeg), 'arg', deg2rad(argDeg), ...
               'tru', deg2rad(truDeg));
end
