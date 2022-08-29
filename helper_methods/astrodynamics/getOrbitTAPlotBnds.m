function [lbTA, ubTA, period] = getOrbitTAPlotBnds(bodyInfo, parentBodyInfo, iniOrbit)
%getOrbitTAPlotBnds Summary of this function goes here
%   Detailed explanation goes here
    if(iniOrbit(2) < 1)
        period = computePeriod(iniOrbit(1), bodyInfo.gm);
        lbTA = 0;
        ubTA = 2*pi;
    else
        rSOI = getSOIRadius(bodyInfo, parentBodyInfo)*0.2;
        if(rSOI > 5*bodyInfo.radius) 
            rSOI = 5*bodyInfo.radius;
        end
        
        [~, rPe] = computeApogeePerigee(iniOrbit(1), iniOrbit(2));
        
        if(rSOI < rPe)
            rSOI = 1.4*rPe;
        end

        iniHyTruMax = AngleZero2Pi(computeTrueAFromRadiusEcc(rSOI, iniOrbit(1), iniOrbit(2)));
        MA = computeMeanFromTrueAnom(-iniHyTruMax, iniOrbit(2));
        meanMotion = computeMeanMotion(iniOrbit(1), bodyInfo.gm);

        period = abs(MA/meanMotion);
        lbTA = -iniHyTruMax;
        ubTA = iniHyTruMax;
    end
end

