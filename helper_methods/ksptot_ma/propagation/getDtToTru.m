function dt = getDtToTru(truTarget, sma, ecc, truINI, gmu)
    if(ecc < 1.0)
        if(abs(truTarget-2*pi) < 1E-8)
            truTarget = 2*pi;
        else
            truTarget = AngleZero2Pi(truTarget);
        end
        truINI = AngleZero2Pi(truINI);
    else
        truINI = angleNegPiToPi(truINI);
        truTarget = angleNegPiToPi(truTarget);
    end

    meanINI = computeMeanFromTrueAnom(truINI, ecc);
    meanMotion = computeMeanMotion(sma, gmu);
    
    if(truTarget >= truINI)
        if(abs(truTarget) < 1E-8)
            meanTarget = 0;
        elseif(abs(truTarget-2*pi) < 1E-8)
            meanTarget = 2*pi;
            if(meanINI < 0)
                meanINI = meanINI + 2*pi;
            end
        else
            meanTarget = computeMeanFromTrueAnom(truTarget, ecc);
        end
        
        dM = meanTarget-meanINI;
        dt = dM/meanMotion;
    else
        dt1 = getDtToTru(2*pi, sma, ecc, truINI, gmu);
        dt2 = getDtToTru(truTarget, sma, ecc, 0, gmu);
        dt = dt1+dt2;
    end
    
    if(isnan(dt) || ~isreal(dt))
        dt = Inf;
    end
end