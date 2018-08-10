function [f, sma, ecc, inc, raan, arg, tru, T, Y, pitchFit, heading] = launchAscentObjFunc(x, rVect0, vVect0, lvDef, tArr, liftoffUt, pitchInterp, gmu, bodyInfo, inds, durScaleFact)

    pitchPts = x(inds(1,1):inds(1,2))';
    heading = x(inds(2,1):inds(2,2));
    ascentDur = x(inds(3,1):inds(3,2)) * durScaleFact;
    coast = x(inds(4,1):inds(4,2)) * durScaleFact;
    
    pitchFit = fit(tArr,pitchPts,pitchInterp);
    
    lvDef2 = lvDef;
    for(i=1:size(lvDef2,1)) %#ok<*NO4LP>
        lvDef2{i,6} = coast(i);
    end
    lvPerfTable = getLVPerfTable(lvDef2, liftoffUt);
    mass0 = lvPerfTable(1,8);
    
    rhs = @(ut, x) propAscentRHS(ut, x, gmu, lvPerfTable, pitchFit, heading, bodyInfo);
    
    tspan = [liftoffUt, liftoffUt + ascentDur];
    x0 = [rVect0', vVect0', mass0];
    options = odeset('RelTol',1E-6,'AbsTol',1E-6);
    [T,Y] = ode45(rhs,tspan,x0,options);
    
    trajEndState = Y(end,:);
    
%     perfRow = lvPerfTable(lvPerfTable(:,1) <= T(end) & T(end) < lvPerfTable(:,2),:);
%     dryMassCum = perfRow(7);
    
    f = -(trajEndState(7)); %maximize mass
%     f = 1;
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(trajEndState(1:3),trajEndState(4:6),gmu);
end