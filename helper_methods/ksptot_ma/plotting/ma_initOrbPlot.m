function [hCBodySurf, hCBodySurfXForm] = ma_initOrbPlot(hFig, orbitDispAxes, bodyInfo)
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
        [X,Y,Z] = sphere(50);
        
        if(not(isempty(bodyInfo.surftexturefile)))
            try
                [I,~] = imread('images/body_textures/surface/kerbinSurface.jpg');
                I = flip(I, 1);
                I = flip(I, 2);
%                 hCBodySurf = warp(dRad*X,dRad*Y,dRad*Z,I);
%                 hCBodySurf.Parent = orbitDispAxes;
                hCBodySurf = surf(orbitDispAxes, dRad*X,dRad*Y,dRad*Z, 'CData',I, 'FaceColor','texturemap', 'BackFaceLighting','lit', 'FaceLighting','gouraud', 'EdgeLighting','gouraud', 'LineStyle','none');
                
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
    else
        hCBodySurf = [];
    end
    axis(orbitDispAxes, 'equal');
    hold(orbitDispAxes,'off');
end

function hCBodySurf = createUntexturedSphere(bodyInfo, orbitDispAxes, dRad, X, Y, Z)
    CData = getCDataForSphereWithColormap(Z, bodyInfo.bodycolor);
    mColor = colorFromColorMap(bodyInfo.bodycolor);
    plot3(orbitDispAxes, 0, 0, 0,'Marker','o','MarkerEdgeColor',mColor,'MarkerFaceColor',mColor,'MarkerSize',3);
    hCBodySurf = surf(orbitDispAxes, dRad*X,dRad*Y,dRad*Z, 'CData',CData, 'BackFaceLighting','lit', 'FaceLighting','gouraud', 'EdgeLighting','gouraud', 'LineWidth',0.1, 'EdgeAlpha',0.1);
    material(hCBodySurf,'dull');
end

