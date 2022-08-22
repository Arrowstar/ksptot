function plotBodyDepartOrbit(departAxis)
%plotBodyDepartOrbit Summary of this function goes here
%   Detailed explanation goes here

    axisUserData = get(departAxis,'UserData');

    dVVect = axisUserData{1,1};
    eRVect = axisUserData{1,2};
    celBodyData = axisUserData{1,3};
    eSMA = axisUserData{1,4};
    eEcc = axisUserData{1,5};
    eInc = axisUserData{1,6};
    eRAAN = axisUserData{1,7};
    eArg = axisUserData{1,8};
    gmuDepartBody = axisUserData{1,9};
    hSMA = axisUserData{1,10};
    hEcc = axisUserData{1,11};
    hInc = axisUserData{1,12};
    hRAAN = axisUserData{1,13};
    hArg = axisUserData{1,14};
    departBody = axisUserData{1,15};
    iniOrbPlotBnd = axisUserData{1,16};
    
    axes(departAxis);
    cla(departAxis);
    set(departAxis,'XTickLabel',[]);
    set(departAxis,'YTickLabel',[]);
    set(departAxis,'ZTickLabel',[]);
    view(2);

    dVVectHat = dVVect/norm(dVVect);
    sc = 300;
    dispDVVectX = [eRVect(1), eRVect(1)+sc*dVVectHat(1)];
    dispDVVectY = [eRVect(2), eRVect(2)+sc*dVVectHat(2)];
    dispDVVectZ = [eRVect(3), eRVect(3)+sc*dVVectHat(3)];
    
    plot3(dispDVVectX, dispDVVectY, dispDVVectZ,'r', 'LineWidth',2');

    dRad = celBodyData.(departBody).radius;
%     bColor = celBodyData.(departBody).bodycolor;
    
    hold on;
%     [X,Y,Z] = sphere(30);
%     surf(dRad*X,dRad*Y,dRad*Z);
%     colormap(bColor);

    ma_initOrbPlot([], departAxis, celBodyData.(departBody));

    plotOrbit('k', eSMA, eEcc, eInc, eRAAN, eArg, iniOrbPlotBnd(1), iniOrbPlotBnd(2), gmuDepartBody);
    
    hTruMax = abs(computeTrueAFromRadiusEcc(5*dRad, hSMA, hEcc));
    htruMax2 = AngleZero2Pi(acos(-1/hEcc));
    truToUse = min(htruMax2,hTruMax);
    
    plotOrbit('k', hSMA, hEcc, hInc, hRAAN, hArg, -truToUse, truToUse, gmuDepartBody,[],[],[],'--');

%     text(dispDVVectX(2), dispDVVectY(2), dispDVVectZ(2),[num2str(norm(dVVect)), ' km/s']);
    
    grid on;
    axis equal;
    hold off;

    set(departAxis,'UserData',axisUserData);
end

