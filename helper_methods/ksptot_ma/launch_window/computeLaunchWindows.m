function [x1, x2, fval1, fval2, beta1, beta2] = computeLaunchWindows(bodyInfo, launchLong, launchLat, targetInc, targetRAAN, windowSearchStartUT)
%computeLaunchWindows Summary of this function goes here
%   Detailed explanation goes here
    %d = "dummy"

    dSMA = bodyInfo.radius + 1;
    dEcc = 0.0;
    dInc = targetInc;
    dRAAN = targetRAAN;
    dArg = 0.0;
    dTru = 0.0;
    gmu = bodyInfo.gm;
    
    [dRVect,dVVect]=getStatefromKepler(dSMA, dEcc, dInc, dRAAN, dArg, dTru, gmu);
    dVVectMag = norm(dVVect);
    dHVect = cross(dRVect,dVVect); 
    dPoint = [0;0;0];
    
    distFunc = @(ut) getDistBetweenPlaneAndLaunchSite(ut, launchLat, launchLong, bodyInfo.radius, bodyInfo, dHVect, dPoint);
    rotPeriod = bodyInfo.rotperiod;
    
    options = optimset('TolX',1E-8);
    
    lb1 = windowSearchStartUT;
    ub1 = windowSearchStartUT + rotPeriod;
    [x1,fval1] = fminbnd(distFunc,lb1,ub1, options);
    
    lb2 = lb1;
    ub2 = x1-1;
    [x21,fval21] = fminbnd(distFunc,lb2,ub2, options);
    
    lb3 = x1+1;
    ub3 = ub1;
    if(ub3<lb3)
        ub3 = abs(ub3-lb3)+lb3;
    end
    [x22,fval22] = fminbnd(distFunc,lb3,ub3, options);
    
    if(fval21 < fval22)
        x2 = x21;
        fval2 = fval21;
    else
        x2 = x22;
        fval2 = fval22;
    end
    
    sinBeta = cos(targetInc)/cos(launchLat);
    beta1 = AngleZero2Pi(getLaunchAz(x1, sinBeta, dHVect, distFunc, bodyInfo, dVVectMag));
    beta2 = AngleZero2Pi(getLaunchAz(x2, sinBeta, dHVect, distFunc, bodyInfo, dVVectMag));
end

function [d, rVectECI] = getDistBetweenPlaneAndLaunchSite(ut, lat, long, alt, bodyInfo, planeNormalVect, planePoint)
    rVectECI = getInertialVectFromLatLongAlt(ut, lat, long, alt, bodyInfo, [NaN;NaN;NaN]);
    
    v = rVectECI - planePoint;
    n = normVector(planeNormalVect); %unit vector
    d = abs(dot(v,n)); %distance between plane and point
end

function beta = getLaunchAz(x, sinBeta, hVect, distFunc, bodyInfo, dVVectMag)
    [~,rVect] = distFunc(x);
    vVect = dVVectMag*normVector(cross(normVector(hVect),normVector(rVect)));
    beta = asin(sinBeta);
    if(vVect(3) < 0)
        beta = pi - beta;
    end
end