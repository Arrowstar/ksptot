function plotFlybyXferTraj(hAxis, departBodyInfo, flybyBodyInfo, arrivalBodyInfo, xferOrbitIn, xferOrbitOut, gmuXfr)
%plotFlybyXferTraj Summary of this function goes here
%   Detailed explanation goes here
    axes(hAxis);
    cla(hAxis, 'reset');
    set(hAxis,'Color',[0 0 0]);
    set(hAxis,'XTick',[], 'XTickMode', 'manual');
    set(hAxis,'YTick',[], 'YTickMode', 'manual');
    set(hAxis,'ZTick',[], 'ZTickMode', 'manual');

    legendHs = [];
    legendStrs = {};
    
    hold on;
    h=plotBodyOrbit(departBodyInfo, 'r', gmuXfr);
    legendHs(end+1) = h;
    legendStrs{end+1} = [cap1stLetter(lower(departBodyInfo.name)), ' Orbit'];
    hold on;
    h=plotBodyOrbit(flybyBodyInfo, 'g', gmuXfr);
    legendHs(end+1) = h;
    legendStrs{end+1} = [cap1stLetter(lower(flybyBodyInfo.name)), ' Orbit'];
    hold on;
    h=plotBodyOrbit(arrivalBodyInfo, 'b', gmuXfr);
    legendHs(end+1) = h;
    legendStrs{end+1} = [cap1stLetter(lower(arrivalBodyInfo.name)), ' Orbit'];
    
    hold on;
    h=plotOrbit('w', xferOrbitIn(1), xferOrbitIn(2), xferOrbitIn(3), xferOrbitIn(4), xferOrbitIn(5), AngleZero2Pi(xferOrbitIn(6)), AngleZero2Pi(xferOrbitIn(7)), gmuXfr);
    legendHs(end+1) = h;
    legendStrs{end+1} = ['Phase 1 Xfer Orbit'];
    hold on;
    h=plotOrbit('w', xferOrbitOut(1), xferOrbitOut(2), xferOrbitOut(3), xferOrbitOut(4), xferOrbitOut(5), AngleZero2Pi(xferOrbitOut(6)), AngleZero2Pi(xferOrbitOut(7)), gmuXfr,[],[],[],'--');
    legendHs(end+1) = h;
    legendStrs{end+1} = ['Phase 2 Xfer Orbit'];
    
    hold on;
    plot3(0,0,0, 'yo', 'MarkerEdgeColor', 'y', 'MarkerFaceColor', 'y', 'MarkerSize', 10);
    
    [rVect, vVect] = getStateAtTime(departBodyInfo, 0, gmuXfr);
    [sma, ecc, inc, longAscNode, ArgPeri, TrueAnom] = getKeplerFromState(rVect,vVect,gmuXfr);
    departBodyOrbit = [sma, ecc, inc, longAscNode, ArgPeri, TrueAnom];
    
    [rVect, vVect] = getStateAtTime(flybyBodyInfo, 0, gmuXfr);
    [sma, ecc, inc, longAscNode, ArgPeri, TrueAnom] = getKeplerFromState(rVect,vVect,gmuXfr);
    flybyBodyOrbit = [sma, ecc, inc, longAscNode, ArgPeri, TrueAnom];

    [rVect, vVect] = getStateAtTime(arrivalBodyInfo, 0, gmuXfr);
    [sma, ecc, inc, longAscNode, ArgPeri, TrueAnom] = getKeplerFromState(rVect,vVect,gmuXfr);
    arriveBodyOrbit = [sma, ecc, inc, longAscNode, ArgPeri, TrueAnom];
    
    hold on;
    plotLineOfNodes(hAxis, departBodyOrbit, flybyBodyOrbit, xferOrbitIn, gmuXfr);
    hold on;
    plotLineOfNodes(hAxis, flybyBodyOrbit, arriveBodyOrbit, xferOrbitOut, gmuXfr);
    
    hold on;
    plotXfrOrbitApses(hAxis, xferOrbitIn, AngleZero2Pi(xferOrbitIn(6)), AngleZero2Pi(xferOrbitIn(7)), gmuXfr);
    hold on;
    plotXfrOrbitApses(hAxis, xferOrbitOut, AngleZero2Pi(xferOrbitOut(6)), AngleZero2Pi(xferOrbitOut(7)), gmuXfr);
    
    [rVect,~]=getStatefromKepler(xferOrbitIn(1), xferOrbitIn(2), xferOrbitIn(3), xferOrbitIn(4), xferOrbitIn(5), AngleZero2Pi(xferOrbitIn(6)), gmuXfr);
    hold on;
    plot3(rVect(1), rVect(2), rVect(3), 'ro', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 10);
    
    [rVect,~]=getStatefromKepler(xferOrbitIn(1), xferOrbitIn(2), xferOrbitIn(3), xferOrbitIn(4), xferOrbitIn(5), AngleZero2Pi(xferOrbitIn(7)), gmuXfr);
    hold on;
    plot3(rVect(1), rVect(2), rVect(3), 'go', 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', 10);
    
    [rVect,~]=getStatefromKepler(xferOrbitOut(1), xferOrbitOut(2), xferOrbitOut(3), xferOrbitOut(4), xferOrbitOut(5), AngleZero2Pi(xferOrbitOut(7)), gmuXfr);
    hold on;
    plot3(rVect(1), rVect(2), rVect(3), 'bo', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b', 'MarkerSize', 10);
    
    hold on;
    axis equal;
    view([0 89]);
    hold off;
    
    title('');
    legend(legendHs, legendStrs, 'Location', 'Best', 'EdgeColor', 'w', 'TextColor', 'w', 'LineWidth', 1.5);
end

