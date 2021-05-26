function [sma, ecc, tru] = computeSmaEccTruFromRVFpa(radius, velocity, fpa, gmu)
    energy = velocity.^2/2 - gmu./radius;
    sma = -gmu./(2*energy);
    
    h = radius*velocity*cos(fpa);
    ecc = sqrt(1 - (h^2)/(sma*gmu));
    
    tru = computeTrueAFromRadiusEcc(radius, sma, ecc);
    if(fpa < 0)
        tru = 2*pi - tru;
    end
end