function [sma, ecc, inc, raan, arg, tru] = vect_getKeplerFromState_Alg(rVect,vVect,gmu)
%vect_getKeplerFromState_Alg Summary of this function goes here
%   Detailed explanation goes here
    numRV = size(rVect,2);

    k_hat = [0; 0; 1];
    k_hat = repmat(k_hat,1,numRV);

    hVect=cross(rVect,vVect);
    h=sqrt(sum(abs(hVect).^2,1));

    r=sqrt(sum(abs(rVect).^2,1));
    v=sqrt(sum(abs(vVect).^2,1));

    nVect = cross(k_hat, hVect);
    eVect1 = reshape(multiprod(reshape(rVect,3,1,numRV),reshape((v.^2 - gmu./r),1,1,numRV)),3,numRV);
    eVect2 = reshape(multiprod(reshape(vVect,3,1,numRV),reshape(dot(rVect,vVect),1,1,numRV)),3,numRV);
%     eVect = (eVect1 - eVect2)./(gmu);
    eVectNoDiv = (eVect1 - eVect2);
    eVect = bsxfun(@times, eVectNoDiv, 1./gmu);
    ecc = sqrt(sum(abs(eVect).^2,1));

    Energy=v.^2/2 - gmu./r;

    if(any(ecc ~= 1.0))
        sma=-gmu./(2.*Energy);
    else
        sma = Inf;
    end

    cosInc = hVect(3,:) ./ h;
    inc = real(acos(complex(cosInc)));

    cosRAAN = nVect(1,:)./sqrt(sum(abs(nVect).^2,1));
    raan = real(acos(complex(cosRAAN)));
    if(any(nVect(2,:) < 0))
        raan(nVect(2,:) < 0) = 2*pi - raan(nVect(2,:) < 0);
    end

    cosArg = dot(nVect, eVect)./(sqrt(sum(abs(nVect).^2,1)) .* sqrt(sum(abs(eVect).^2,1)));
    arg = real(acos(complex(cosArg)));
    if(any(eVect(3,:) < 0))
        arg(eVect(3,:) < 0) = 2*pi - arg(eVect(3,:) < 0);
    end

    cosTru = dot(eVect, rVect) ./ (sqrt(sum(abs(eVect).^2,1)) .* sqrt(sum(abs(rVect).^2,1)));
    tru = real(acos(complex(cosTru)));
    if(any(dot(rVect,vVect)<0))
        tru(dot(rVect,vVect)<0) = -tru(dot(rVect,vVect)<0);
    end
    
    %%%%%%%%%%
    % Special Case: Elliptical Equitorial
    %%%%%%%%%%
    bool2 = (ecc >= 1E-10) & ((inc < 1E-10) | (abs(inc-pi) < 1E-10));
    if(any(bool2))
        longPeri = real(acos(complex(eVect(1,:)./sqrt(sum(abs(eVect).^2,1)))));
        if(any(eVect(2,:) < 0))
            longPeri(eVect(2,:) < 0) = 2*pi - longPeri(eVect(2,:) < 0);
        end  
        raan(bool2) = 0;
        arg(bool2) = longPeri(bool2);
    end

    %%%%%%%%%%
    % Special Case: Circular Inclined
    %%%%%%%%%%
    bool2 = (ecc < 1E-10) & (inc >= 1E-10) & (abs(inc-pi) >= 1E-10);
    if(any(bool2))
        u = real(acos(complex(dot(nVect,rVect)./(sqrt(sum(abs(nVect).^2,1)).*sqrt(sum(abs(rVect).^2,1)) ))));
        if(any(rVect(3,:) < 0))
            u(rVect(3,:) < 0) = 2*pi - u(rVect(3,:) < 0);
        end
        tru(bool2) = u(bool2);
        arg(bool2) = 0;
    end

    %%%%%%%%%%
    % Special Case: Circular Equitorial
    %%%%%%%%%%
    bool2 = (ecc < 1E-10) & ((inc < 1E-10) | (abs(inc-pi) < 1E-10));
    if(any(bool2))
        l = real(acos(complex(rVect(1,:)./sqrt(sum(abs(rVect).^2,1)) )));
        if(any(rVect(2,:)<0))
            l(rVect(2,:)<0) = 2*pi-l(rVect(2,:)<0);
        end
        tru(bool2) = l(bool2);

        raan(bool2) = 0;
        arg(bool2) = 0;
    end
end

