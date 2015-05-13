function hBody = ma_plotChildBody(bodyInfo, child, time, gmu, orbitDispAxes, showSoI, showChildMarker, celBodyData)
    [rVect, ~] = getStateAtTime(child, time, gmu);

    dRad = bodyInfo.radius;
    [X,Y,Z] = sphere(20);
    hold(orbitDispAxes,'on');
    hBody = surf(orbitDispAxes, rVect(1)+dRad*X,rVect(2)+dRad*Y,rVect(3)+dRad*Z);
    if(showChildMarker)
        plot3(orbitDispAxes,rVect(1),rVect(2),rVect(3),'Color','k','Marker','o','MarkerFaceColor','k','MarkerSize',4.5);
    end
    
    parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
    if(showSoI && ~isempty(parentBodyInfo))
        r = getSOIRadius(bodyInfo, getParentBodyInfo(bodyInfo, celBodyData));
        plotOrbit('k', r, 0, deg2rad(bodyInfo.inc), deg2rad(bodyInfo.raan), deg2rad(bodyInfo.arg), 0, 2*pi, parentBodyInfo.gm, gca, rVect,1.5,'--');
    end
end