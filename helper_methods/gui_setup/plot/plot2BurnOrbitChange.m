function plot2BurnOrbitChange(hAxis, bodyInfo, iniOrbit, finOrbit, xfrOrbit, deltaV1, deltaV1R, deltaV2, deltaV2R, celBodyData)
%plot2BurnOrbitChange Summary of this function goes here
%   Detailed explanation goes here

    gmuXfr = bodyInfo.gm;
    
    [parentBodyInfo] = getParentBodyInfo(bodyInfo, celBodyData);

    [iniLB, iniUB, ~] = getOrbitTAPlotBnds(bodyInfo, parentBodyInfo, iniOrbit);
    [finLB, finUB, ~] = getOrbitTAPlotBnds(bodyInfo, parentBodyInfo, finOrbit);

    axes(hAxis);
    cla(hAxis,'reset');
    set(hAxis,'XTickLabel',[]);
    set(hAxis,'YTickLabel',[]);
    set(hAxis,'ZTickLabel',[]);
    hold on;
    dRad = bodyInfo.radius;
    [X,Y,Z] = sphere(30);
    surf(dRad*X,dRad*Y,dRad*Z);
    colormap(bodyInfo.bodycolor);

    plotOrbit('m', iniOrbit(1), iniOrbit(2), iniOrbit(3), iniOrbit(4), iniOrbit(5), iniLB, iniUB, gmuXfr);
    plotOrbit('b', finOrbit(1), finOrbit(2), finOrbit(3), finOrbit(4), finOrbit(5), finLB, finUB, gmuXfr);
    plotOrbit('k', xfrOrbit(1), xfrOrbit(2), xfrOrbit(3), xfrOrbit(4), xfrOrbit(5), xfrOrbit(6), xfrOrbit(7), gmuXfr,[],[],[],'--');

    sc=300;
    dv1ToPlot = [deltaV1R(1), deltaV1R(2), deltaV1R(3);
                 deltaV1R(1)+sc*deltaV1(1), deltaV1R(2)+sc*deltaV1(2), deltaV1R(3)+sc*deltaV1(3)];
    dv2ToPlot = [deltaV2R(1), deltaV2R(2), deltaV2R(3);
                 deltaV2R(1)+sc*deltaV2(1), deltaV2R(2)+sc*deltaV2(2), deltaV2R(3)+sc*deltaV2(3)];
    hold on;
	plot3(dv1ToPlot(:,1), dv1ToPlot(:,2), dv1ToPlot(:,3), 'r', 'LineWidth', 2);
    hold on;
    plot3(dv2ToPlot(:,1), dv2ToPlot(:,2), dv2ToPlot(:,3), 'r', 'LineWidth', 2);

    grid on;
    axis equal;
    view(3);
    hold off;
end

