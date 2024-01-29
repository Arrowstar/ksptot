clc; clear all; format long g; close all;

hFig = figure();
hAx = axes(hFig);
hold(hAx,'on');

[X,Y,Z] = sphere(50);
scale2 = 100;
h1=surf(hAx, scale2*X,          scale2*Y,          scale2*Z,          "EdgeColor","none", "FaceColor",'r', 'EdgeAlpha',0.5, 'FaceLighting','flat');
h2=surf(hAx, scale2*X+20*scale2,scale2*Y+20*scale2,scale2*Z+0*scale2, "EdgeColor","none", "FaceColor",'b', 'EdgeAlpha',0.5, 'FaceLighting','flat');
light(hAx, 'Style','infinite', 'Position',[0 0 1000]); 

theta = 0:0.01:2*pi;
x = 1.5*scale2*cos(theta);
y = 1.5*scale2*sin(theta);
plot(hAx, x,y, 'Color','g');

cameraPos = [-10*scale2,0,0];
campos(hAx, cameraPos);
camtarget(hAx, [1,0,0]);
camva(hAx, 45);
grid(hAx,'off');
axis(hAx,'equal');
hAx.XTick = [];
hAx.YTick = [];
hAx.ZTick = [];
hAx.Box = "off";
hAx.XColor = "none";
hAx.YColor = "none";
hAx.ZColor = "none";
camproj(hAx, 'perspective'); %THIS IS REQUIRED TO MAKE A "SKYBOX" WORK!!!
cameratoolbar(hFig);
hAx.Clipping = "off";
hAx.ClippingStyle = "3dbox";

lFh = @(src,evt) updateSkyboxPos(src,evt, hAx);
addlistener(hAx,'CameraPosition','PostSet', lFh);
lFh([],[]);

lFh = @(src,evt) updateCamTgtPos(src,evt, hAx, hFig);
addlistener(hAx,'CameraPosition','PostSet', lFh);

function updateSkyboxPos(~,~, hAx)
    global SkyBoxSurfHandle skyboxOrigin skyboxRadius

    cameraPos = campos(hAx);

    if(isempty(skyboxOrigin) || isempty(skyboxRadius) || norm(cameraPos - skyboxOrigin) > 0.5*skyboxRadius) %only update skybox sphere if we get too close to the edge
        if(not(isempty(SkyBoxSurfHandle)) && isvalid(SkyBoxSurfHandle))
            SkyBoxSurfHandle.Visible = 'off'; %This makes sure that the axes bounds are set without including the skybox.  Just turn the skybox back on later. 
        end
    
        xBndMaxDistToCamPos = max(abs(cameraPos(1) - xlim(hAx)));
        yBndMaxDistToCamPos = max(abs(cameraPos(2) - ylim(hAx)));
        zBndMaxDistToCamPos = max(abs(cameraPos(3) - zlim(hAx)));
        
        skyboxSize = 10*max([xBndMaxDistToCamPos, yBndMaxDistToCamPos, zBndMaxDistToCamPos]);
        
        skyboxOrigin = cameraPos;
        skyboxRadius = skyboxSize;

        [X,Y,Z] = sphere(30);
        if(isempty(SkyBoxSurfHandle) || not(isvalid(SkyBoxSurfHandle)))
            I = imread('eso0932a.tif');
            % I = imread('peppers.png');
            I = flipud(I);
    
            hold(hAx,'on');
            SkyBoxSurfHandle = surf(hAx, skyboxSize*X+cameraPos(1),skyboxSize*Y+cameraPos(2),skyboxSize*Z+cameraPos(3), "EdgeColor","none", "FaceColor","texturemap", 'CData',I, 'FaceLighting','none');
        else
            SkyBoxSurfHandle.XData = skyboxSize*X+cameraPos(1);
            SkyBoxSurfHandle.YData = skyboxSize*Y+cameraPos(2);
            SkyBoxSurfHandle.ZData = skyboxSize*Z+cameraPos(3);
            SkyBoxSurfHandle.Visible = 'on';
        end
    end
end

function updateCamTgtPos(~,~, hAx, hFig)
    global camPosTgtDist

    if(strcmpi(cameratoolbar(hFig,"GetMode"), 'dollyfb'))
        if(isempty(camPosTgtDist))
            camPosTgtDist = norm(camtarget(hAx) - campos(hAx));
        else
            posTgtNorm = norm(camtarget(hAx) - campos(hAx));
            posTgtUnitVect = (camtarget(hAx) - campos(hAx))/posTgtNorm;

            newCamTgt = campos(hAx) + camPosTgtDist*posTgtUnitVect;
            camtarget(hAx, newCamTgt);
        end
    end
end