function xdot = propAscentRHS(ut, x, gmu, lvPerfTable, pitchFit, headingAngle, bodyInfo)
    rVect = x(1:3);
    r = norm(rVect);
    vVect = x(4:6);
    m = x(7);
    
    perfRow = lvPerfTable(lvPerfTable(:,1) <= ut & ut < lvPerfTable(:,2),:);
    dryMassCum = perfRow(7);
    m = m + dryMassCum;
    if(ut >= perfRow(1) && ut < perfRow(9))
        thrust = perfRow(3);
        mdot = perfRow(4);
        cDa = perfRow(10);
    else
        thrust = 0;
        mdot = 0;
        cDa = 1;
    end
    
    pitchAngle = pitchFit(ut);
    vect = getPointingVectFromPitchHeading(rVect', pitchAngle, headingAngle);
    thrustVec = (thrust*vect')/1000/m;
    
    gAccel = -(gmu/r^3)*rVect; %km^3/s^2 / km^2 = km/s^2    
    
    dragCoeff = cDa;
    dragAccel = getDragAccel(bodyInfo, ut, rVect, vVect, dragCoeff, m, 'Stock');
%     dragAccel = 0;
    
    xdot(1:3) = vVect;
    xdot(4:6) = gAccel + thrustVec + dragAccel;
    xdot(7) = mdot;
    
    xdot = xdot';    
end