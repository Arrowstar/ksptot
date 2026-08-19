function coe = refRv2Coe(rVect, vVect, gmu)
% refRv2Coe Independent reference conversion: state -> Keplerian elements.
%
% Textbook formulation (Vallado, Algorithm 9).  Returns a struct rather
% than a fixed argument list so that the degenerate-orbit auxiliary
% angles are available to tests that need them.
%
% Degenerate orbits are reported using the convention that actually
% round-trips through refCoe2Rv, including the retrograde equatorial case:
% because a retrograde equatorial orbit reconstructed with raan = 0 and
% inc = pi picks up a perifocal-to-inertial matrix of diag(1,-1,-1), the
% in-plane angle must be measured clockwise rather than counterclockwise.
%
% OUTPUT FIELDS
%   sma, ecc, inc, raan, arg, tru - classical elements [km, ND, rad]
%   argLat    - argument of latitude (circular inclined) [rad]
%   lonPeri   - longitude of periapsis (elliptical equatorial) [rad]
%   trueLon   - true longitude (circular equatorial) [rad]
%   isCircular, isEquatorial - degeneracy flags
%   specificEnergy, hVect, eVect, nVect - intermediate quantities

    tol = 1e-10;

    rVect = rVect(:);
    vVect = vVect(:);

    r = norm(rVect);
    v = norm(vVect);

    hVect = cross(rVect, vVect);
    h     = norm(hVect);

    nVect = cross([0; 0; 1], hVect);
    n     = norm(nVect);

    eVect = ((v^2 - gmu / r) * rVect - dot(rVect, vVect) * vVect) / gmu;
    ecc   = norm(eVect);

    specificEnergy = v^2 / 2 - gmu / r;

    if(abs(ecc - 1) > tol)
        sma = -gmu / (2 * specificEnergy);
    else
        sma = Inf;
    end

    inc = acos(max(-1, min(1, hVect(3) / h)));

    isEquatorial = (inc < tol) || (abs(inc - pi) < tol);
    isCircular   = ecc < tol;

    % --- RAAN -----------------------------------------------------------
    if(~isEquatorial)
        raan = acos(max(-1, min(1, nVect(1) / n)));
        if(nVect(2) < 0)
            raan = 2 * pi - raan;
        end
    else
        raan = 0;
    end

    % --- Argument of periapsis ------------------------------------------
    if(~isEquatorial && ~isCircular)
        arg = acos(max(-1, min(1, dot(nVect, eVect) / (n * ecc))));
        if(eVect(3) < 0)
            arg = 2 * pi - arg;
        end
    elseif(isCircular)
        arg = 0;
    else
        arg = localPlanarAngle(eVect, inc);
    end

    % --- True anomaly ----------------------------------------------------
    if(~isCircular)
        tru = acos(max(-1, min(1, dot(eVect, rVect) / (ecc * r))));
        if(dot(rVect, vVect) < 0)
            tru = 2 * pi - tru;
        end
    elseif(~isEquatorial)
        tru = acos(max(-1, min(1, dot(nVect, rVect) / (n * r))));
        if(rVect(3) < 0)
            tru = 2 * pi - tru;
        end
    else
        tru = localPlanarAngle(rVect, inc);
    end

    % --- Auxiliary angles -------------------------------------------------
    argLat  = NaN;
    lonPeri = NaN;
    trueLon = NaN;

    if(isCircular && ~isEquatorial)
        argLat = tru;
    end

    if(~isCircular && isEquatorial)
        lonPeri = arg;
    end

    if(isCircular && isEquatorial)
        trueLon = tru;
    end

    coe = struct('sma', sma, 'ecc', ecc, 'inc', inc, 'raan', raan, ...
                 'arg', arg, 'tru', tru, ...
                 'argLat', argLat, 'lonPeri', lonPeri, 'trueLon', trueLon, ...
                 'isCircular', isCircular, 'isEquatorial', isEquatorial, ...
                 'specificEnergy', specificEnergy, ...
                 'hVect', hVect, 'eVect', eVect, 'nVect', nVect);
end

function ang = localPlanarAngle(vect, inc)
%localPlanarAngle In-plane angle of a vector for an equatorial orbit.
%
% Measured counterclockwise for prograde (inc ~ 0) and clockwise for
% retrograde (inc ~ pi), which is what makes the result reproduce the
% original state when reconstructed with raan = 0.

    ang = acos(max(-1, min(1, vect(1) / norm(vect(1:2)))));

    isRetrograde = abs(inc - pi) < abs(inc);

    if(~isRetrograde)
        if(vect(2) < 0)
            ang = 2 * pi - ang;
        end
    else
        if(vect(2) > 0)
            ang = 2 * pi - ang;
        end
    end
end
