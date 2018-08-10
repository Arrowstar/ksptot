function tru = getTAFromLineOfNodes(nVect, sma, ecc, inc, raan, arg, gmu) 

    func = @(tru) dangBetweenRVectAndLineToAscNode(nVect, sma, ecc, inc, raan, arg, tru, gmu);
    if(ecc < 1)
        tru = fminbnd(func, 0, 2*pi, optimset('TolX',eps));
    else
        maxTA = computeTrueAFromRadiusEcc(Inf, sma, ecc);
        tru = fminbnd(func, -maxTA, maxTA, optimset('TolX',eps));
    end
end

function angle = dangBetweenRVectAndLineToAscNode(nVect, sma, ecc, inc, raan, arg, tru, gmu)
    [rVect,~]=getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu);
    angle = dang(nVect,rVect);
end