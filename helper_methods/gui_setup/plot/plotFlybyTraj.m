function plotFlybyTraj(hAxis, flybyBodyInfo, flyByOrbitIn, flyByOrbitOut, flyByDVVect, celBodyData)
%plotFlybyTraj Summary of this function goes here
%   Detailed explanation goes here
    axes(hAxis);
    cla(hAxis,'reset');
    set(hAxis,'XTickLabel',[]);
    set(hAxis,'YTickLabel',[]);
    set(hAxis,'ZTickLabel',[]);
    
    [eRVect, ~] = getStatefromKepler(flyByOrbitIn(1), flyByOrbitIn(2), flyByOrbitIn(3), flyByOrbitIn(4), flyByOrbitIn(5), 0.0, flybyBodyInfo.gm);
    dVVectHat = flyByDVVect/norm(flyByDVVect);
    sc = 300;
    dispDVVectX = [eRVect(1), eRVect(1)+sc*dVVectHat(1)];
    dispDVVectY = [eRVect(2), eRVect(2)+sc*dVVectHat(2)];
    dispDVVectZ = [eRVect(3), eRVect(3)+sc*dVVectHat(3)];

    dRad=flybyBodyInfo.radius;
    hold on;
    [X,Y,Z] = sphere(30);
    surf(dRad*X,dRad*Y,dRad*Z);
    colormap(flybyBodyInfo.bodycolor);
    
    [parentBodyInfo] = getParentBodyInfo(flybyBodyInfo, celBodyData);
    rSOI = getSOIRadius(flybyBodyInfo, parentBodyInfo)*0.1;
    if(rSOI > 5*flybyBodyInfo.radius) 
        rSOI = 5*flybyBodyInfo.radius;
    end
    rSOI = max(max(1.25*flyByOrbitIn(7), 1.25*flyByOrbitOut(7)), rSOI);
    
    iniHyTruMax = AngleZero2Pi(computeTrueAFromRadiusEcc(rSOI, flyByOrbitIn(1), flyByOrbitIn(2)));
    iniHyTruMin = AngleZero2Pi(computeTrueAFromRadiusEcc(rSOI, flyByOrbitOut(1), flyByOrbitOut(2)));
         
    iniHyTruMax = min(iniHyTruMax, pi-iniHyTruMax);
    iniHyTruMin = min(iniHyTruMin, pi-iniHyTruMin);
    
    plotOrbit('k', flyByOrbitIn(1), flyByOrbitIn(2), flyByOrbitIn(3), flyByOrbitIn(4), flyByOrbitIn(5), -iniHyTruMin, 0, flybyBodyInfo.gm);
    plotOrbit('k', flyByOrbitOut(1), flyByOrbitOut(2), flyByOrbitOut(3), flyByOrbitOut(4), flyByOrbitOut(5), 0, iniHyTruMax, flybyBodyInfo.gm,[],[],[],'--');
    
    hold on;
    plot3(dispDVVectX, dispDVVectY, dispDVVectZ,'r', 'LineWidth',2');

    view(3);
    grid(hAxis,'on');
    axis equal;
    hold off;
    zoom reset;
end

