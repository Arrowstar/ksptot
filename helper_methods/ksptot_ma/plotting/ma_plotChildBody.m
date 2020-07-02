function hBody = ma_plotChildBody(bodyInfo, child, time, gmu, orbitDispAxes, showSoI, showChildMarker, celBodyData)
    [rVect, ~] = getStateAtTime(child, time, getParentGM(child, celBodyData));

    dRad = bodyInfo.radius;
    [X,Y,Z] = sphere(20);
    hold(orbitDispAxes,'on');
    CData = getCDataForSphereWithColormap(Z, bodyInfo.bodycolor);
    
    hBody = surf(orbitDispAxes, rVect(1)+dRad*X,rVect(2)+dRad*Y,rVect(3)+dRad*Z,'CData',CData);
    if(showChildMarker)
        plot3(orbitDispAxes,rVect(1),rVect(2),rVect(3),'Color','k','Marker','o','MarkerFaceColor','k','MarkerSize',4.5);
    end
    
    parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
    if(showSoI && ~isempty(parentBodyInfo))
        r = getSOIRadius(bodyInfo, parentBodyInfo);
        plotOrbit('k', r, 0, deg2rad(bodyInfo.inc), deg2rad(bodyInfo.raan), deg2rad(bodyInfo.arg), 0, 2*pi, getParentGM(bodyInfo, celBodyData), gca, rVect,1.5,'--');
    end
end