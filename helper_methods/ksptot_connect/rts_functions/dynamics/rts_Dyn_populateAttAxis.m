function rts_Dyn_populateAttAxis(hFig, hAttDispAxes,attData)
%rts_Dyn_populateAttAxis Summary of this function goes here
%   Detailed explanation goes here
    persistent hX hXText hY hYText hZ hZText hCone EndPlate1 EndPlate2 hXB hXBText hYB hYBText hZB hZBText az el hRates hRatesText;
    if(ishandle(hX))
        delete(hX);
    end
    if(ishandle(hXText))
        delete(hXText);
    end
    if(ishandle(hY))
        delete(hY);
    end
    if(ishandle(hYText))
        delete(hYText);
    end
    if(ishandle(hZ))
        delete(hZ);
    end
    if(ishandle(hZText))
        delete(hZText);
    end
    if(ishandle(hCone))
        delete(hCone);
    end
    if(ishandle(EndPlate1))
        delete(EndPlate1);
    end
    if(ishandle(EndPlate2))
        delete(EndPlate2);
    end
    if(ishandle(hXB))
        delete(hXB);
    end
    if(ishandle(hYB))
        delete(hYB);
    end
    if(ishandle(hYBText))
        delete(hYBText);
    end
    if(ishandle(hXBText))
        delete(hXBText);
    end
    if(ishandle(hZB))
        delete(hZB);
    end
    if(ishandle(hZBText))
        delete(hZBText);
    end
    if(ishandle(hRates))
        delete(hRates);
    end
    if(ishandle(hRatesText))
        delete(hRatesText);
    end
    
    if(isempty(az) || isempty(el))
        az = -37.5;
        el= 30;
    else 
        [az, el] = view(hAttDispAxes);
    end

    hold(hAttDispAxes,'on');
    axis(hAttDispAxes);
    [hX, hXText, hY, hYText, hZ, hZText, hCone, EndPlate1, EndPlate2, hXB, hXBText, hYB, hYBText, hZB, hZBText, hRates, hRatesText] = populateAttPlotWAtt(attData, hAttDispAxes);
    rts_initOrbPlot(hFig, hAttDispAxes, []);
    view(hAttDispAxes, az, el);
    hold(hAttDispAxes,'off');
end

function [hX, hXText, hY, hYText, hZ, hZText, hCone,EndPlate1,EndPlate2, hXB, hXBText, hYB, hYBText, hZB, hZBText, hRates, hRatesText] =  populateAttPlotWAtt(attData, hAttDispAxes)
    e1 = attData(16);
    e2 = attData(17);
    e3 = attData(18);
    e4 = attData(19);
    
    xRate = rad2deg(attData(28));
    yRate = rad2deg(attData(29));
    zRate = rad2deg(attData(30));
    rateVect = [xRate, yRate, zRate];
    if(norm(rateVect) > 0.0)
        rateVect = rateVect / norm(rateVect);
    else
        rateVect = [0,0,0];
    end
    
    C(1,1)=1 - 2*e2^2 - 2*e3^2;
    C(1,2)=2*(e1*e2 - e3*e4);
    C(1,3)=2*(e3*e1 + e2*e4);
    C(2,1)=2*(e1*e2 + e3*e4);
    C(2,2)=1 - 2*e3^2 - 2*e1^2;
    C(2,3)=2*(e2*e3 - e1*e4);
    C(3,1)=2*(e3*e1 - e2*e4);
    C(3,2)=2*(e2*e3 + e1*e4);
    C(3,3)=1 - 2*e1^2 - 2*e2^2;

    xRot = (C)*[1;0;0];
    xRot = xRot/norm(xRot);
    
    zRot = (C)*[0;0;1];
    zRot = (zRot/norm(zRot));
   
    R1 = [cos(pi/2) -sin(pi/2) 0;
          sin(pi/2) cos(pi/2) 0;
          0 0 1];
    R2 = [1 0 0;
          0 cos(pi/2) -sin(pi/2);
          0 sin(pi/2) cos(pi/2)];
    R3 = [cos(pi/2) 0 sin(pi/2);
          0 1 0;
          -sin(pi/2) 0 cos(pi/2)];

    R2 = R2(:,[1:2-1,3,2+1:3-1,2,3+1:end]);  
    R3 = R2(:,[1:2-1,3,2+1:3-1,2,3+1:end]);
	R = R1*R2*R3;
    
    xRot = R*xRot;
    zRot = R*zRot;
    
    yRot = cross(zRot, xRot);
    yRot = -yRot/norm(yRot);
       
    zRotNorm = 0.7*zRot/norm(zRot);
    
    yRot =0.7*yRot;
    xRot =0.7*xRot;

    X1 = [0 0 0]';
    X2 = 0.5*zRot;
    R = [0.25 0.05];
    n = 30;
    cyl_color = 'r';
    closed = 1;
    lines = 0;
    [hCone,EndPlate1,EndPlate2] = Cone(hAttDispAxes, X1,X2,R,n,cyl_color,closed,lines);

    hX = plot3(hAttDispAxes, [-1 1], [0 0], [0 0],'LineWidth',1.5);
    hXB = plot3(hAttDispAxes, [0 xRot(1)], [0 xRot(2)], [0 xRot(3)],'m','LineWidth',1.5);
    hXText = text(1.05,0,0,'x','Color','k', 'FontWeight', 'bold', 'Parent', hAttDispAxes);
    hXBText = text(xRot(1),xRot(2),xRot(3),'x_b','Color','k', 'FontWeight', 'bold', 'Parent', hAttDispAxes);
    
    hY = plot3(hAttDispAxes, [0 0], [-1 1], [0 0],'LineWidth',1.5);
    hYB = plot3(hAttDispAxes, [0 yRot(1)], [0 yRot(2)], [0 yRot(3)],'m','LineWidth',1.5);
    hYText = text(0,1.05,0,'y','Color','k', 'FontWeight', 'bold', 'Parent', hAttDispAxes); 
    hYBText = text(yRot(1),yRot(2),yRot(3),'y_b','Color','k', 'FontWeight', 'bold', 'Parent', hAttDispAxes); 
    
    hZ = plot3(hAttDispAxes, [0 0], [0 0], [-1 1],'LineWidth',1.5);
    hZB = plot3(hAttDispAxes, [0 zRotNorm(1)], [0 zRotNorm(2)], [0 zRotNorm(3)],'m','LineWidth',1.5);
    hZText = text(0,0,1.05,'z','Color','k', 'FontWeight', 'bold', 'Parent', hAttDispAxes); 
    hZBText = text(zRotNorm(1),zRotNorm(2),zRotNorm(3),'z_b','Color','k', 'FontWeight', 'bold', 'Parent', hAttDispAxes); 

    hRates = plot3(hAttDispAxes, [0 rateVect(1)], [0 rateVect(2)], [0 rateVect(3)],'g','LineWidth',1.5);
    hRatesText = text(rateVect(1),rateVect(2),rateVect(3),'h_hat','Color','k', 'FontWeight', 'bold', 'Parent', hAttDispAxes); 
    
%     sunvect = [-0.3, 0.2, 0.1];
%     sunvect = sunvect/norm(sunvect);
%     sunVectText= 1.05*sunvect;
%     sunTextColor = [218,165,32]/256;
%     plot3([0 sunvect(1)], [0 sunvect(2)], [0 sunvect(3)],'LineWidth',1.5, 'Color',sunTextColor);
%     text(sunVectText(1), sunVectText(2), sunVectText(3),'Sun','Color',sunTextColor, 'FontWeight', 'bold'); 
% 
%     celBodyvect = -[0.75 0.75 0.75];
%     celBodyvect = celBodyvect/norm(celBodyvect);
%     celBodyvectText= 1.05*celBodyvect;
%     celBodyTextColor = [0,100,0]/256;
%     plot3([0 celBodyvect(1)], [0 celBodyvect(2)], [0 celBodyvect(3)],'LineWidth',1.5, 'Color',celBodyTextColor);
%     text(celBodyvectText(1), celBodyvectText(2), celBodyvectText(3),'Kerbin','Color',celBodyTextColor, 'FontWeight', 'bold'); 

end