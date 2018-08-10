function hCBodySurf = ma_initOrbPlot(hFig, orbitDispAxes, bodyInfo)
%ma_initOrbPlot Summary of this function goes here
%   Detailed explanation goes here

    hold(orbitDispAxes,'on');
    set(orbitDispAxes,'XTickLabel',[]);
    set(orbitDispAxes,'YTickLabel',[]);
    set(orbitDispAxes,'ZTickLabel',[]);
    grid(orbitDispAxes,'on');
    view(orbitDispAxes,3);

    if(~isempty(bodyInfo))
        dRad = bodyInfo.radius;
        [X,Y,Z] = sphere(20);
        CData = getCDataForSphereWithColormap(Z, bodyInfo.bodycolor);
        hold(orbitDispAxes,'on');
        mColor = colorFromColorMap(bodyInfo.bodycolor);
        plot3(orbitDispAxes, 0, 0, 0,'Marker','o','MarkerEdgeColor',mColor,'MarkerFaceColor',mColor,'MarkerSize',3);
        hCBodySurf = surf(orbitDispAxes, dRad*X,dRad*Y,dRad*Z,'CData',CData,'BackFaceLighting','lit','FaceLighting','gouraud','LineWidth',0.1,'EdgeAlpha',1);
        hold(orbitDispAxes,'on');
%         colormap(orbitDispAxes,bodyInfo.bodycolor);
    else
        hCBodySurf = [];
    end
    axis(orbitDispAxes, 'equal');
    hold(orbitDispAxes,'off');    
end

