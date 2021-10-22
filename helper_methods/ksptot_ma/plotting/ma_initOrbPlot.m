function [hCBodySurf, hCBodySurfXForm] = ma_initOrbPlot(hFig, orbitDispAxes, bodyInfo)
    %ma_initOrbPlot Summary of this function goes here
    %   Detailed explanation goes here
    
    hold(orbitDispAxes,'on');
    set(orbitDispAxes,'XTickLabel',[]);
    set(orbitDispAxes,'YTickLabel',[]);
    set(orbitDispAxes,'ZTickLabel',[]);
    grid(orbitDispAxes,'on');

    axis(orbitDispAxes, 'equal');
    
    axis(orbitDispAxes, 'tight');
    
    if(~isempty(bodyInfo))
        dRad = bodyInfo.radius;
        [X,Y,Z] = sphere(50);
        
        if(not(isempty(bodyInfo.surftexturefile)))
            try
                I = bodyInfo.getSurfaceTexture();
                if(not(isempty(I)) && not(any(any(any(isnan(I))))))
                    hCBodySurf = surf(orbitDispAxes, dRad*X,dRad*Y,dRad*Z, 'CData',I, 'FaceColor','texturemap', 'BackFaceLighting','lit', 'FaceLighting','gouraud', 'EdgeLighting','gouraud', 'LineStyle','none');
                else
                    hCBodySurf = createUntexturedSphere(bodyInfo, orbitDispAxes, dRad, X, Y, Z);
                end
                
            catch ME
                if(exist('hCBodySurf','var'))
                    delete(hCBodySurf); %#ok<NODEF>
                    warning('Could not create textured celestial body "%s".  Error message: \n\n%s', bodyInfo.name, ME.message);
                end
                
                hCBodySurf = createUntexturedSphere(bodyInfo, orbitDispAxes, dRad, X, Y, Z);
            end
            
        else
            hCBodySurf = createUntexturedSphere(bodyInfo, orbitDispAxes, dRad, X, Y, Z);
        end
        
        hCBodySurfXForm = hgtransform('Parent', orbitDispAxes);
        set(hCBodySurf,'Parent',hCBodySurfXForm); 
        material(hCBodySurf,'dull');
    else
        hCBodySurf = [];
    end
    
    mColor = colorFromColorMap(bodyInfo.bodycolor);
    plot3(orbitDispAxes, 0, 0, 0,'Marker','o','MarkerEdgeColor',mColor,'MarkerFaceColor',mColor,'MarkerSize',3);
    
    hold(orbitDispAxes, 'off');
end

