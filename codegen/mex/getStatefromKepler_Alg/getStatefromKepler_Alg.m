function [rVect, vVect] = getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, gmu)
%getStatefromKepler_Alg Summary of this function goes here
%   Detailed explanation goes here

    %%%%%%%%%%
    % Special Case: Circular Equitorial
    %%%%%%%%%%
    if(ecc < 1E-10 && (inc < 1E-10 || abs(inc-pi) < 1E-10))
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
        arg = 0.0;
    end

    %%%%%%%%%%
    % Special Case: Elliptical Equitorial
    %%%%%%%%%%
    if(ecc >= 1E-10 && (inc < 1E-10 || abs(inc-pi) < 1E-10))
        raan = 0;
    end

    p = sma*(1-ecc^2);
    rPQW = [p*cos(tru) / (1 + ecc*cos(tru));
            p*sin(tru) / (1 + ecc*cos(tru));
            0];

    vPQW = [-sqrt(gmu/p)*sin(tru);
            sqrt(gmu/p)*(ecc + cos(tru));
            0];

    TransMatrix = [cos(raan)*cos(arg)-sin(raan)*sin(arg)*cos(inc), -cos(raan)*sin(arg)-sin(raan)*cos(arg)*cos(inc), sin(raan)*sin(inc);
                   sin(raan)*cos(arg)+cos(raan)*sin(arg)*cos(inc), -sin(raan)*sin(arg)+cos(raan)*cos(arg)*cos(inc), -cos(raan)*sin(inc);
                   sin(arg)*sin(inc),                              cos(arg)*sin(inc),                               cos(inc)];

    rVect = TransMatrix * rPQW;
    vVect = TransMatrix * vPQW;
end