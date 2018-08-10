function [rVect, vVect] = vect_getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, gmu)
%getStatefromKepler_Alg Summary of this function goes here
%   Detailed explanation goes here
    numOrb = length(tru);

    %%%%%%%%%%
    % Special Case: Circular Equitorial
    %%%%%%%%%%
    bool = ecc < 1E-10 & (inc < 1E-10 | abs(inc-pi) < 1E-10);
    if(any(bool))
        l = zeros(size(bool));
        l(bool) = raan(bool) + arg(bool) + tru(bool);
        tru(bool) = l(bool);
        raan(bool) = 0;
        arg(bool) = 0;
    end

    %%%%%%%%%%
    % Special Case: Circular Inclined
    %%%%%%%%%%
    bool = ecc < 1E-10 & inc >= 1E-10 & abs(inc-pi) >= 1E-10;
    if(any(bool))
        u(bool) = arg(bool) + tru(bool);
        tru(bool) = u(bool);
        arg(bool) = 0.0; %may need to remove this, new addition
    end

    %%%%%%%%%%
    % Special Case: Elliptical Equitorial
    %%%%%%%%%%
    bool = ecc >= 1E-10 & (inc < 1E-10 | abs(inc-pi) < 1E-10);
    if(any(bool))
        raan(bool) = 0;
    end

    p = sma.*(1-ecc.^2);
    rPQW = [p.*cos(tru) ./ (1 + ecc.*cos(tru));
            p.*sin(tru) ./ (1 + ecc.*cos(tru));
            zeros(1,length(tru))];

    vPQW = [-sqrt(gmu./p).*sin(tru);
            sqrt(gmu./p).*(ecc + cos(tru));
            zeros(1,length(tru))];

    TransMatrix = [reshape(cos(raan).*cos(arg)-sin(raan).*sin(arg).*cos(inc),1,1,numOrb), ...
                   reshape(-cos(raan).*sin(arg)-sin(raan).*cos(arg).*cos(inc),1,1,numOrb), ...
                   reshape(sin(raan).*sin(inc),1,1,numOrb);
                   reshape(sin(raan).*cos(arg)+cos(raan).*sin(arg).*cos(inc),1,1,numOrb), ...
                   reshape(-sin(raan).*sin(arg)+cos(raan).*cos(arg).*cos(inc),1,1,numOrb), ...
                   reshape(-cos(raan).*sin(inc),1,1,numOrb);
                   reshape(sin(arg).*sin(inc),1,1,numOrb),...
                   reshape(cos(arg).*sin(inc),1,1,numOrb),...
                   reshape(cos(inc),1,1,numOrb)];

%     TransMatrix = reshape(TransMatrix,3,3,numOrb);
    rPQW = reshape(rPQW, 3,1,numOrb);
    vPQW = reshape(vPQW, 3,1,numOrb);

    rVect = multiprod(TransMatrix, rPQW);
    vVect = multiprod(TransMatrix, vPQW);
    
    rVect = reshape(rVect, 3,numOrb);
    vVect = reshape(vVect, 3,numOrb);
end

