function [rVect, vVect] = refCoe2Rv(sma, ecc, inc, raan, arg, tru, gmu)
% refCoe2Rv Independent reference conversion: Keplerian elements -> state.
%
% Straight textbook perifocal-to-inertial transformation (Vallado,
% "Fundamentals of Astrodynamics and Applications", Algorithm 10) with NO
% special-case handling of degenerate orbits.  Elements are taken at face
% value, which makes this an unambiguous oracle: whatever convention the
% code under test uses for circular/equatorial orbits, the elements it
% returns must still reproduce the original state when pushed through
% this function.
%
% INPUTS
%   sma  - semi-major axis [km] (negative for hyperbolic orbits)
%   ecc  - eccentricity [ND]
%   inc  - inclination [rad]
%   raan - right ascension of the ascending node [rad]
%   arg  - argument of periapsis [rad]
%   tru  - true anomaly [rad]
%   gmu  - gravitational parameter [km^3/s^2]
%
% OUTPUTS
%   rVect - 3x1 position vector [km]
%   vVect - 3x1 velocity vector [km/s]

    semiLatusRectum = sma * (1 - ecc^2);

    radius = semiLatusRectum / (1 + ecc * cos(tru));

    rPQW = [radius * cos(tru); ...
            radius * sin(tru); ...
            0];

    vPQW = [-sqrt(gmu / semiLatusRectum) * sin(tru); ...
             sqrt(gmu / semiLatusRectum) * (ecc + cos(tru)); ...
             0];

    % Perifocal -> inertial is Rz(-raan) * Rx(-inc) * Rz(-arg), built here
    % as an explicit product of the three elementary rotations so that the
    % oracle shares no algebra with the implementation under test.
    rotArg  = [cos(-arg),  sin(-arg), 0; ...
              -sin(-arg),  cos(-arg), 0; ...
                       0,          0, 1];

    rotInc  = [1,          0,         0; ...
               0,  cos(-inc), sin(-inc); ...
               0, -sin(-inc), cos(-inc)];

    rotRaan = [cos(-raan),  sin(-raan), 0; ...
              -sin(-raan),  cos(-raan), 0; ...
                        0,           0, 1];

    pqw2eci = rotRaan * rotInc * rotArg;

    rVect = pqw2eci * rPQW;
    vVect = pqw2eci * vPQW;
end
