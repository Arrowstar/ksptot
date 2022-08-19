function [rVectB, vVectB] = getPositOfBodyWRTSun_alg_fast(times, smas, eccs, incs, raans, args, means, epochs, parentGMs)   
    numTimes = length(times);
    rVectB = zeros(3,numTimes);
    vVectB = zeros(3,numTimes);
    for(i = 1:length(parentGMs))       
        [rVect, vVect] = getStateAtTime_alg_fast(times, smas(i), eccs(i), incs(i), raans(i), args(i), means(i), epochs(i), parentGMs(i));
        rVectB = rVectB + rVect;
        vVectB = vVectB + vVect;
    end
end

function [rVect, vVect] = getStateAtTime_alg_fast(time, sma, ecc, inc, raan, arg, mean, epoch, gmu)
%getStateAtTime Summary of this function goes here
%   Detailed explanation goes here
    numTimes = length(time);

    oneArray = (zeros(1, numTimes)+1);
    
    sma = sma * oneArray;
    ecc = ecc * oneArray;
    inc = AngleZero2Pi(deg2rad(inc)) * oneArray;
    raan = AngleZero2Pi(deg2rad(raan)) * oneArray;
    argp = AngleZero2Pi(deg2rad(arg)) * oneArray;
    M0 = deg2rad(mean) * oneArray; 
       
    n = computeMeanMotion(sma, gmu);
    deltaT = time - epoch;
    M = (M0(:) + n(:).*deltaT(:))';
    tru = computeTrueAnomFromMean(M, ecc);

    [rVect,vVect] = getStatefromKepler_Alg(sma, ecc, inc, raan, argp, tru, gmu); 
    
    rVect(isnan(rVect)) = 0;
    vVect(isnan(vVect)) = 0;
end

function [tru] = computeTrueAnomFromMean(means, eccs)
%computeTrueAnomFromMean Summary of this function goes here
%   Detailed explanation goes here
    tru = zeros(size(means));
    for(i=1:length(means))
        mean = means(i);
        ecc = eccs(i);
        
        EAHA = solveKepler(mean, ecc);
        if(ecc < 1.0)
            tru(i) = computeTrueAnomFromEccAnom(EAHA, ecc);
        else
            tru(i) = computeTrueAnomFromHypAnom(EAHA, ecc);
        end
    end
end

function [EccA] = solveKepler(mean, ecc)
%solveKepler Summary of this function goes here
%   Detailed explanation goes here.
    tol = 1E-12;

    if(ecc < 1)
        if(mean < 0 || mean > 2*pi)
            mean = AngleZero2Pi(mean);
        end
        if(abs(mean - 0) < 1E-8)
            EccA = 0;
            return
        elseif(abs(mean - pi) < 1E-8 )
            EccA = pi;
            return;
        end
        EccA = keplerEq(mean,ecc,tol);
    else
        if(abs(mean - 0) < 1E-8)
            EccA = 0;
            return
        else
            EccA = keplerEqHyp(mean,ecc,tol);
        end
    end
end

function E = keplerEq(M,e,eps)
% Function solves Kepler's equation M = E-e*sin(E)
% Input - Mean anomaly M [rad] , Eccentricity e and Epsilon 
% Output  eccentric anomaly E [rad]. 
   	En  = M;
	Ens = En - (En-e*sin(En)- M)/(1 - e*cos(En));
	while( abs(Ens-En) > eps )
		En = Ens;
		Ens = En - (En - e*sin(En) - M)/(1 - e*cos(En));
	end
	E = Ens;
end

function [H] = keplerEqHyp(M,e, eps)
%keplerEqHyp Summary of this function goes here
%   Detailed explanation goes here

    if(e < 1.6)
        if((-pi < M && M < 0) || M > pi)
            H = M - e;
        else
            H = M + e;
        end
    else
        if(e < 3.6 && abs(M)>pi)
            H = M - sign(M)*e;
        else
            H = M/(e - 1);
        end
    end
    
    Hn = M;
    Hn1 = H;
    while(abs(Hn1 - Hn) > eps)
        Hn = Hn1;
        Hn1 = Hn + (M - e*sinh(Hn) + Hn)/(e*cosh(Hn) - 1);
        
        if(isnan(Hn1))
            if(-e*sinh(Hn) == Inf)
                Hn1 = Hn + 1;
            elseif(-e*sinh(Hn) == -Inf)
                Hn1 = Hn - 1;
            end
        end
    end
    
    H = Hn1;
end

function [tru] = computeTrueAnomFromEccAnom(EccA, ecc)
%computeTrueAnomFromEccAnom Summary of this function goes here
%   Detailed explanation goes here
    
    upper = sqrt(1+ecc) .* tan(EccA/2);
    lower = sqrt(1-ecc);
    tru = AngleZero2Pi(atan2(upper, lower) * 2);
end

function [tru] = computeTrueAnomFromHypAnom(HypA, ecc)
%computeTrueAnomFromHypAnom Summary of this function goes here
%   Detailed explanation goes here

    upper = sqrt(ecc+1) .* tanh(HypA/2);
    lower = sqrt(ecc-1);
    tru = atan2(upper, lower) * 2;
end

function [rVect, vVect] = getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, gmu)
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
        u = zeros(size(tru));
        u(bool) = arg(bool) + tru(bool);
        tru(bool) = u(bool);
        arg(bool) = 0.0;
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

%     rVect = multiprod(TransMatrix, rPQW);
%     vVect = multiprod(TransMatrix, vPQW);

    rVect = zeros(3,numOrb);
    vVect = zeros(3,numOrb);
    for(i=1:numOrb) %#ok<*NO4LP> 
        rVect(:,i) = TransMatrix(:,:,i) * rPQW(:,i);
        vVect(:,i) = TransMatrix(:,:,i) * vPQW(:,i);
    end
    
%     rVect = reshape(rVect, 3,numOrb);
%     vVect = reshape(vVect, 3,numOrb);
end