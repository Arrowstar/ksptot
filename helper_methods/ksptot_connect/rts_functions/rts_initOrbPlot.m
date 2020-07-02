function hBodySurf = rts_initOrbPlot(hFig, orbitDispAxes, bodyInfo)
%rts_initOrbPlot Summary of this function goes here
%   Detailed explanation goes here
    
    hold(orbitDispAxes,'on');
    set(orbitDispAxes,'XTickLabel',[]);
    set(orbitDispAxes,'YTickLabel',[]);
    set(orbitDispAxes,'ZTickLabel',[]);
    grid(orbitDispAxes,'on');
    view(orbitDispAxes,3);

    if(~isempty(bodyInfo))
        dRad = bodyInfo.radius;
        [X,Y,Z] = sphere(30);
        hold(orbitDispAxes,'on');
        hBodySurf = surf(orbitDispAxes, dRad*X,dRad*Y,dRad*Z);
        hold(orbitDispAxes,'on');
        colormap(orbitDispAxes,bodyInfo.bodycolor);
    else
        hBodySurf = [];
    end
    axis(orbitDispAxes, 'equal');
    hold(orbitDispAxes,'off');
end

