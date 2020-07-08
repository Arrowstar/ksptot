function sunDotNormal = computeSunDotNormal(ut, long, bodyInfo, celBodyData)    
    rVectSunSC = -1.0 * getPositOfBodyWRTSun(ut, bodyInfo, celBodyData);
    
    if(norm(rVectSunSC) == 0)
        sunDotNormal = 1.0;
    else
        rVectSunECEF = getFixedFrameVectFromInertialVect(ut, rVectSunSC, bodyInfo);
        rECEF = getrVectEcefFromLatLongAlt(zeros(size(long)), long, zeros(size(long)), bodyInfo);
        
        planarRvectEcef = [rECEF(1,:); rECEF(2,:); zeros(1,size(rECEF,2))];
        planarRvectSunEcef = [rVectSunECEF(1,:); rVectSunECEF(2,:); zeros(1,size(rVectSunECEF,2))];

        hra = angleNegPiToPi(dang(planarRvectEcef,planarRvectSunEcef));

        sunDotNormal = 0.5 * cos(hra + deg2rad(45)) + 0.5;
    end
end