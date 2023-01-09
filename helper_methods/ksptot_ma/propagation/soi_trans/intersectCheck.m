function [TF] = intersectCheck(sma1, ecc1, inc1, raan1, arg1,...
                          sma2, ecc2, inc2, raan2, arg2,...
                          gmu, rSoI)
%intersectCheck Summary of this function goes here
%   Detailed explanation goes here

    hVectBody = computeHVect(sma2, ecc2, inc2, raan2, arg2, gmu);
    hVectSC = computeHVect(sma1, ecc1, inc1, raan1, arg1, gmu);

    dangH = dang(hVectSC,hVectBody);
    xR = 2*rSoI/tan(dangH);
    xR = max(xR,2*rSoI);

    nHat = cross(hVectSC,hVectBody);
    nHat = normVector(nHat);

    thetaHat1 = normVector(cross(normVector(hVectSC),nHat));
    theta1 = atan2(nHat(3),thetaHat1(3));
    truOfAN_Body = AngleZero2Pi(theta1 - arg1);
    truOfDN_Body = AngleZero2Pi(truOfAN_Body+pi);
    [rVectAN_Body,~]=getStatefromKepler(sma1, ecc1, inc1, raan1, arg1, truOfAN_Body, gmu);
    [rVectDN_Body,~]=getStatefromKepler(sma1, ecc1, inc1, raan1, arg1, truOfDN_Body, gmu);

    thetaHat2 = normVector(cross(normVector(hVectBody),nHat));
    theta2 = atan2(nHat(3),thetaHat2(3));
    truOfAN_SC = AngleZero2Pi(theta2 - arg2);
    truOfDN_SC = AngleZero2Pi(truOfAN_SC+pi);
    [rVectAN_SC,~]=getStatefromKepler(sma2, ecc2, inc2, raan2, arg2, truOfAN_SC, gmu);
    [rVectDN_SC,~]=getStatefromKepler(sma2, ecc2, inc2, raan2, arg2, truOfDN_SC, gmu);

    if(norm(rVectAN_SC-rVectAN_Body) > xR && ...
       norm(rVectAN_SC-rVectDN_Body) > xR && ...
       norm(rVectDN_SC-rVectAN_Body) > xR && ...
       norm(rVectDN_SC-rVectDN_Body) > xR && ...
       inc1 > 1E-6 && inc2 > 1E-6 && ...
       ecc1 > 1E-6 && ecc2 > 1E-6)
        TF = false;
    else
        TF = true;
    end
    
%     [X,Y,Z] = sphere(30);
%     X = rVectAN_SC(1)+xR*X;
%     Y = rVectAN_SC(2)+xR*Y;
%     Z = rVectAN_SC(3)+xR*Z;
%     
%     [X2,Y2,Z2] = sphere(30);
%     X2 = rVectDN_SC(1)+xR*X2;
%     Y2 = rVectDN_SC(2)+xR*Y2;
%     Z2 = rVectDN_SC(3)+xR*Z2;
% 
%     nHat = 1E7*nHat;
%     figure()
%     hold on;
%     surf(X,Y,Z);
%     surf(X2,Y2,Z2);
%     plot3([-nHat(1) nHat(1)],[-nHat(2) nHat(2)],[-nHat(3) nHat(3)]);
%     plot3([0 rVectAN_Body(1)],[0 rVectAN_Body(2)],[0 rVectAN_Body(3)],'r');
%     plot3([0 rVectAN_SC(1)],[0 rVectAN_SC(2)],[0 rVectAN_SC(3)],'g');
%     plot3([0 rVectDN_Body(1)],[0 rVectDN_Body(2)],[0 rVectDN_Body(3)],'r');
%     plot3([0 rVectDN_SC(1)],[0 rVectDN_SC(2)],[0 rVectDN_SC(3)],'g');
%     plotOrbit('r', sma1, ecc1, inc1, raan1, arg1, 0, 2*pi, gmu);
%     plotOrbit('b', sma2, ecc2, inc2, raan2, arg2, 0, 2*pi, gmu);
%     hold off;
%     axis equal;
end

