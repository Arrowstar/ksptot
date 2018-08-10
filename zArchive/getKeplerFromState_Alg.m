function [sma, ecc, inc, raan, arg, tru] = getKeplerFromState_Alg(rVect,vVect,gmu)
%getKeplerFromState_Alg Summary of this function goes here
%   Detailed explanation goes here
    k_hat = [0; 0; 1];

    hVect=crossARH(rVect,vVect);
    h=norm(hVect);

    r=norm(rVect);
    v=norm(vVect);

    nVect = crossARH(k_hat, hVect);
    eVect = ((v^2 - gmu/r)*rVect - dotARH(rVect,vVect)*vVect)/gmu;
    ecc = norm(eVect);

    Energy=v^2/2 - gmu/r;

    if(ecc ~= 1.0)
        sma=-gmu/(2*Energy);
%         p = sma*(1-ecc^2);
    else
        sma = Inf;
%         p = h^2/gmu;
    end

    cosInc = hVect(3) / h;
    inc = real(acos(complex(cosInc)));

    cosRAAN = nVect(1)/norm(nVect);
    raan = real(acos(complex(cosRAAN)));
    if(nVect(2) < 0)
        raan = 2*pi - raan;
    end

    cosArg = dotARH(nVect, eVect)/(norm(nVect) * norm(eVect));
    arg = real(acos(complex(cosArg)));
    if(eVect(3) < 0)
        arg = 2*pi - arg;
    end

    cosTru = dotARH(eVect, rVect) / (norm(eVect) * norm(rVect));
    tru = real(acos(complex(cosTru)));
    if(dotARH(rVect,vVect)<0)
        tru = -tru;
%         tru = 2*pi - tru; %this is the same thing as far as I can tell!
    end

    %%%%%%%%%%
    % Special Case: Elliptical Equitorial
    %%%%%%%%%%
    if(ecc >= 1E-10 && (inc < 1E-10 || abs(inc-pi) < 1E-10))
        cosLongPeri = eVect(1)/norm(eVect);
        if(eVect(2) < 0)
            cosLongPeri = 2*pi - cosLongPeri;
        end  
        raan = 0; %these two lines are my convention, hopefully they work
        arg = cosLongPeri;
    end

    %%%%%%%%%%
    % Special Case: Circular Inclined
    %%%%%%%%%%
    if(ecc < 1E-10 && inc >= 1E-10 && abs(inc-pi) >= 1E-10)
        u = real(acos(complex(dotARH(nVect,rVect)/(norm(nVect)*norm(rVect)))));
        if(rVect(3) < 0)
            u = 2*pi - u;
        end
        tru = u;

        arg = 0;
    end

    %%%%%%%%%%
    % Special Case: Circular Equitorial
    %%%%%%%%%%
    if(ecc < 1E-10 && (inc < 1E-10 || abs(inc-pi) < 1E-10))
        l = real(acos(complex(rVect(1)/norm(rVect))));
        if(rVect(2)<0)
            l = 2*pi-l;
        end
        tru = l;

        raan = 0;
        arg = 0;
    end
end

