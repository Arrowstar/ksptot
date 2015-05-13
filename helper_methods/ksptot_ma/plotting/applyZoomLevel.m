function applyZoomLevel(hMaGUI)
    zoomLevel = getappdata(hMaGUI,'plotZoomSliderPosit');
    zoomLevel = min(zoomLevel,1.0);
    zoomLevel = max(0.01, zoomLevel);
    if(isempty(zoomLevel))
        zoomLevel = 1.0;
        setappdata(hMaGUI,'plotZoomSliderPosit',zoomLevel);
        h = findobj('Tag','zoomSlider');
        set(h,'Value',zoomLevel);
    end
%     xlims = xlim(gca);
%     ylims = ylim(gca);
%     zlims = zlim(gca);
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
    
    if(zoomLevel <= 1.0)
        if(abs(xlims(1)) > abs(xlims(2)))
            newX = xlims(1) * zoomLevel;
            if(abs(newX) < abs(xlims(2)))
                xlim([newX -newX]);
            else
                xlim([newX xlims(2)]);
            end
        else
            newX = xlims(2) * zoomLevel;
            if(abs(newX) < abs(xlims(1)))
                xlim([-newX newX]);
            else
                xlim([xlims(1) newX]);
            end
        end
        
        if(abs(ylims(1)) > abs(ylims(2)))
            newX = ylims(1) * zoomLevel;
            if(abs(newX) < abs(ylims(2)))
                ylim([newX -newX]);
            else
                ylim([newX ylims(2)]);
            end
        else
            newX = ylims(2) * zoomLevel;
            if(abs(newX) < abs(ylims(1)))
                ylim([-newX newX]);
            else
                ylim([ylims(1) newX]);
            end
        end
        
        if(abs(zlims(1)) > abs(zlims(2)))
            newX = zlims(1) * zoomLevel;
            if(abs(newX) < abs(zlims(2)))
                zlim([newX -newX]);
            else
                zlim([newX zlims(2)]);
            end
        else
            newX = zlims(2) * zoomLevel;
            if(abs(newX) < abs(zlims(1)))
                zlim([-newX newX]);
            else
                zlim([zlims(1) newX]);
            end
        end

    end
end