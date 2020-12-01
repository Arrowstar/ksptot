function hra = computeHourAngle_alg(ut, long, rotperiod, rotini, radius, smas, eccs, incs, raans, args, means, epochs, parentGMs)
%     rVectBodyToSun = -1.0 * getPositOfBodyWRTSun(ut, bodyInfo, celBodyData);
    rVectBodyToSun = -1.0 * getPositOfBodyWRTSun_alg(ut, smas, eccs, incs, raans, args, means, epochs, parentGMs);
    rVectBodyToSun = reshape(rVectBodyToSun, 3,numel(ut));
    rVectBodyToSunNorm = sqrt(sum(rVectBodyToSun.^2,1));
    
%     rVectSunECEF = getFixedFrameVectFromInertialVect(ut, rVectBodyToSun, bodyInfo);
    rVectSunECEF = getFixedFrameVectFromInertialVect_alg(ut, rVectBodyToSun, rotperiod, rotini);
    rECEF = getrVectEcefFromLatLongAlt_alg(zeros(size(long)), long, zeros(size(long)), radius);

    planarRvectEcef = [rECEF(1,:); rECEF(2,:); zeros(1,size(rECEF,2))];
    planarRvectSunEcef = [rVectSunECEF(1,:); rVectSunECEF(2,:); zeros(1,size(rVectSunECEF,2))];

    hra = angleNegPiToPi(dang(planarRvectEcef,planarRvectSunEcef));
    hra(rVectBodyToSunNorm == 0) = 1.0;
    hra = reshape(hra,size(ut));
end