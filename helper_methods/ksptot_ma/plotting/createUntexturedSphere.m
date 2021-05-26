function hCBodySurf = createUntexturedSphere(bodyInfo, orbitDispAxes, dRad, X, Y, Z)
    CData = getCDataForSphereWithColormap(Z, bodyInfo.bodycolor);
    hCBodySurf = surf(orbitDispAxes, dRad*X,dRad*Y,dRad*Z, 'CData',CData, 'BackFaceLighting','lit', 'FaceLighting','gouraud', 'EdgeLighting','gouraud', 'LineWidth',0.1, 'EdgeAlpha',0.1);
end