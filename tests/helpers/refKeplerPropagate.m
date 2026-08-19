function [rVect, vVect] = refKeplerPropagate(rVect0, vVect0, gmu, dt)
% refKeplerPropagate Analytic two-body propagation oracle.
%
% Advances a Cartesian state by dt seconds under pure point-mass gravity
% using classical elements and Kepler's equation.  Deliberately shares no
% code with the production propagators or with getStatefromKepler, so it
% can be used as an independent check on the numerical integrators.
%
% INPUTS
%   rVect0 - 3x1 initial position
%   vVect0 - 3x1 initial velocity
%   gmu    - gravitational parameter
%   dt     - time offset (may be negative)
%
% OUTPUTS
%   rVect, vVect - 3x1 propagated state

    coe = refRv2Coe(rVect0, vVect0, gmu);

    sma = coe.sma;
    ecc = coe.ecc;

    if(ecc < 1)
        meanMotion = sqrt(gmu / sma^3);

        eccAnom0 = 2 * atan2(sqrt(1 - ecc) * sin(coe.tru / 2), ...
                             sqrt(1 + ecc) * cos(coe.tru / 2));
        meanAnom0 = eccAnom0 - ecc * sin(eccAnom0);

        meanAnom = meanAnom0 + meanMotion * dt;
        eccAnom  = localSolveElliptic(meanAnom, ecc);

        tru = 2 * atan2(sqrt(1 + ecc) * sin(eccAnom / 2), ...
                        sqrt(1 - ecc) * cos(eccAnom / 2));
    else
        meanMotion = sqrt(gmu / (-sma)^3);

        hypAnom0 = 2 * atanh(sqrt((ecc - 1) / (ecc + 1)) * tan(coe.tru / 2));
        meanAnom0 = ecc * sinh(hypAnom0) - hypAnom0;

        meanAnom = meanAnom0 + meanMotion * dt;
        hypAnom  = localSolveHyperbolic(meanAnom, ecc);

        tru = 2 * atan2(sqrt(ecc + 1) * sinh(hypAnom / 2), ...
                        sqrt(ecc - 1) * cosh(hypAnom / 2));
    end

    [rVect, vVect] = refCoe2Rv(sma, ecc, coe.inc, coe.raan, coe.arg, tru, gmu);
end

function eccAnom = localSolveElliptic(meanAnom, ecc)
%localSolveElliptic Newton iteration on E - e*sin(E) = M.

    meanAnom = mod(meanAnom, 2 * pi);

    if(ecc < 0.8)
        eccAnom = meanAnom;
    else
        eccAnom = pi;
    end

    for(iter = 1:200) %#ok<*NO4LP>
        residual = eccAnom - ecc * sin(eccAnom) - meanAnom;
        slope    = 1 - ecc * cos(eccAnom);

        step = residual / slope;
        eccAnom = eccAnom - step;

        if(abs(step) < 1e-14)
            break;
        end
    end
end

function hypAnom = localSolveHyperbolic(meanAnom, ecc)
%localSolveHyperbolic Newton iteration on e*sinh(H) - H = M.

    if(abs(meanAnom) < 6)
        hypAnom = meanAnom / (ecc - 1);
    else
        hypAnom = sign(meanAnom) * log(2 * abs(meanAnom) / ecc + 1.8);
    end

    for(iter = 1:200)
        residual = ecc * sinh(hypAnom) - hypAnom - meanAnom;
        slope    = ecc * cosh(hypAnom) - 1;

        step = residual / slope;

        % Damp the first steps so a poor initial guess cannot overshoot
        % into the flat region of sinh where Newton diverges.
        if(abs(step) > 1)
            step = sign(step);
        end

        hypAnom = hypAnom - step;

        if(abs(residual) < 1e-13 * max(1, abs(meanAnom)))
            break;
        end
    end
end
