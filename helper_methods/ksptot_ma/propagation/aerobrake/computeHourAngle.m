function hra = computeHourAngle(ut, long, bodyInfo, celBodyData)
    rVectBodyToSun = -1.0 * getPositOfBodyWRTSun(ut, bodyInfo, celBodyData);
    rVectBodyToSun = reshape(rVectBodyToSun, 3,numel(ut));
    rVectBodyToSunNorm = sqrt(sum(rVectBodyToSun.^2,1));
    
    rVectSunECEF = getFixedFrameVectFromInertialVect(ut, rVectBodyToSun, bodyInfo);
    rECEF = getrVectEcefFromLatLongAlt(zeros(size(long)), long, zeros(size(long)), bodyInfo);

    planarRvectEcef = [rECEF(1,:); rECEF(2,:); zeros(1,size(rECEF,2))];
    planarRvectSunEcef = [rVectSunECEF(1,:); rVectSunECEF(2,:); zeros(1,size(rVectSunECEF,2))];

    hra = angleNegPiToPi(dang(planarRvectEcef,planarRvectSunEcef));
    hra(rVectBodyToSunNorm == 0) = 1.0;
    hra = reshape(hra,size(ut));
end