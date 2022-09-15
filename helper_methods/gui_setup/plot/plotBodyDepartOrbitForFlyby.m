function plotBodyDepartOrbitForFlyby(hAxis, departBodyInfo, eOrbit, hOrbit, dVVect, eRVect)
%plotBodyDepartOrbitForFlyby Summary of this function goes here
%   Detailed explanation goes here

    eSMA = eOrbit(1);
    eEcc = eOrbit(2);
    eInc = eOrbit(3);
    eRAAN = eOrbit(4);
    eArg = eOrbit(5);
    gmuDepartBody = departBodyInfo.gm;
    hSMA = hOrbit(1);
    hEcc = hOrbit(2);
    hInc = hOrbit(3);
    hRAAN = hOrbit(4);
    hArg = hOrbit(5);
    
    axes(hAxis);
    cla(hAxis,'reset');
    set(hAxis,'XTickLabel',[]);
    set(hAxis,'YTickLabel',[]);
    set(hAxis,'ZTickLabel',[]);
    view(3);
    
    dVVectHat = dVVect/norm(dVVect);
    sc = 300;
    dispDVVectX = [eRVect(1), eRVect(1)+sc*dVVectHat(1)];
    dispDVVectY = [eRVect(2), eRVect(2)+sc*dVVectHat(2)];
    dispDVVectZ = [eRVect(3), eRVect(3)+sc*dVVectHat(3)];
    
    dRad = departBodyInfo.radius;
    bColor = departBodyInfo.bodycolor;
    
    hold on;
    [X,Y,Z] = sphere(30);
    surf(dRad*X,dRad*Y,dRad*Z);
    colormap(bColor);
    plotOrbit('k', eSMA, eEcc, eInc, eRAAN, eArg, 0, 2*pi, gmuDepartBody);
    
    hTruMax = abs(computeTrueAFromRadiusEcc(5*dRad, hSMA, hEcc));
    htruMax2 = AngleZero2Pi(acos(-1/hEcc));
    truToUse = min(htruMax2,hTruMax);
    
    plotOrbit('k', hSMA, hEcc, hInc, hRAAN, hArg, -truToUse, truToUse, gmuDepartBody,[],[],[],'--');
    hold on;
    plot3(dispDVVectX, dispDVVectY, dispDVVectZ,'r', 'LineWidth',2');
    
    grid(hAxis,'on');
    axis equal;
    hold off;
    zoom reset;
end

