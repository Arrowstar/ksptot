function applyZoomLevel(hMaGUI, handles, celBodyData)
    zoomLevel = getappdata(hMaGUI,'plotZoomSliderPosit');
    zoomLevel = min(zoomLevel,1.0);
    zoomLevel = max(0.01, zoomLevel);
    if(isempty(zoomLevel))
        zoomLevel = 1.0;
        setappdata(hMaGUI,'plotZoomSliderPosit',zoomLevel);
        h = findobj('Tag','zoomSlider');
        set(h,'Value',zoomLevel);
    end

    xlims = getappdata(hMaGUI,'dispOrbitXLim');
    ylims = getappdata(hMaGUI,'dispOrbitYLim');
    zlims = getappdata(hMaGUI,'dispOrbitZLim');
    
    if(isempty(xlims))
        xlims = xlim(gca);
    end
    if(isempty(ylims))
        ylims = ylim(gca);
    end
    if(isempty(zlims))
        zlims = zlim(gca);
    end
    
    bodyID = getappdata(handles.dispAxes,'CurCentralBodyId');
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    bodyRad = bodyInfo.radius;
    
    if(zoomLevel <= 1.0)
        if(abs(xlims(1)) > abs(xlims(2)))
            newX = xlims(1) * zoomLevel;            
            if(abs(newX) < abs(xlims(2)))
                xLimBnds = [newX -newX];
                
            else
                xLimBnds = [newX xlims(2)];
            end
        else
            newX = xlims(2) * zoomLevel;
            if(abs(newX) < abs(xlims(1)))
                xLimBnds = [-newX newX];
            else
                xLimBnds = [xlims(1) newX];
            end
        end
        if(abs(xLimBnds(1)) < bodyRad)
            xLimBnds(1) = -bodyRad;
        end
        if(abs(xLimBnds(2)) < bodyRad)
            xLimBnds(2) = bodyRad;
        end
        xlim(xLimBnds);
        
        if(abs(ylims(1)) > abs(ylims(2)))
            newX = ylims(1) * zoomLevel;
            if(abs(newX) < abs(ylims(2)))
                yLimBnds = [newX -newX];
            else
                yLimBnds = [newX ylims(2)];
            end
        else
            newX = ylims(2) * zoomLevel;
            if(abs(newX) < abs(ylims(1)))
                yLimBnds = [-newX newX];
            else
                yLimBnds = [ylims(1) newX];
            end
        end
        if(abs(yLimBnds(1)) < bodyRad)
            yLimBnds(1) = -bodyRad;
        end
        if(abs(yLimBnds(2)) < bodyRad)
            yLimBnds(2) = bodyRad;
        end
        ylim(yLimBnds);
        
        if(abs(zlims(1)) > abs(zlims(2)))
            newX = zlims(1) * zoomLevel;
            if(abs(newX) < abs(zlims(2)))
                zLimBnds = [newX -newX];
            else
                zLimBnds = [newX zlims(2)];
            end
        else
            newX = zlims(2) * zoomLevel;
            if(abs(newX) < abs(zlims(1)))
                zLimBnds = [-newX newX];
            else
                zLimBnds = [zlims(1) newX];
            end
        end
        if(abs(zLimBnds(1)) < bodyRad)
            zLimBnds(1) = -bodyRad;
        end
        if(abs(zLimBnds(2)) < bodyRad)
            zLimBnds(2) = bodyRad;
        end
        zlim(zLimBnds);
    end
end