function [rVect, vVect] = getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, gmu)
% getStatefromKepler_Alg() takes a set of Keplerian orbital elements and turns
% them into a set of state vectors (position and velocity vectors).
%
% This is a scalar implementation with retrograde equatorial bug fix.

    %%%%%%%%%%
    % Special Case: Circular Equatorial (Prograde Only)
    %%%%%%%%%%
    if(ecc < 1E-10 && (inc < 1E-10))
        l = raan + arg + tru;
        tru = l;
        raan = 0;
        arg = 0;
    end

    %%%%%%%%%%
    % Special Case: Circular Inclined
    %%%%%%%%%%
    if(ecc < 1E-10 && inc >= 1E-10 && abs(inc-pi) >= 1E-10)
        u = arg + tru;
        tru = u;
        arg = 0;
    end

    %%%%%%%%%%
    % Special Case: Elliptical Equatorial (Prograde Only)
    %%%%%%%%%%
    if(ecc >= 1E-10 && (inc < 1E-10))
        arg = raan + arg; % Transfer the rotation to arg
        raan = 0;
    end

    % General conversion logic
    p = sma * (1 - ecc^2);
    rPQW = [p * cos(tru) / (1 + ecc * cos(tru));
            p * sin(tru) / (1 + ecc * cos(tru));
            0];

    vPQW = [-sqrt(gmu / p) * sin(tru);
            sqrt(gmu / p) * (ecc + cos(tru));
            0];

    % Rotation Matrix: Rz(-raan) * Rx(-inc) * Rz(-arg) 
    % (Standard ECI to PQW is Rz(arg)*Rx(inc)*Rz(raan), so ECI->PQW is (PQW->ECI)')
    % PQW to ECI is TransMatrix
    
    sinR = sin(raan);
    cosR = cos(raan);
    sinI = sin(inc);
    cosI = cos(inc);
    sinA = sin(arg);
    cosA = cos(arg);
    
    TransMatrix = [cosR*cosA-sinR*sinA*cosI, -cosR*sinA-sinR*cosA*cosI,  sinR*sinI;
                   sinR*cosA+cosR*sinA*cosI, -sinR*sinA+cosR*cosA*cosI, -cosR*sinI;
                   sinA*sinI,                 cosA*sinI,                 cosI];

    rVect = TransMatrix * rPQW;
    vVect = TransMatrix * vPQW;
end
