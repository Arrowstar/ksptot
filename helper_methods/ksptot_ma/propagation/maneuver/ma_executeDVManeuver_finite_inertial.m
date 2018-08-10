function eventLog = ma_executeDVManeuver_finite_inertial(dVVectECI, thruster, initialState, eventNum, celBodyData)
%ma_executeDVManeuver_finite_inertial Summary of this function goes here
%   Detailed explanation goes here

    ut = initialState(1);
    rVectUT = initialState(2:4);
    vVectUT = initialState(5:7);
    bodyID = initialState(8);
    mass0 = sum(initialState(9:12));
    
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
       
    isp = thruster.isp;
    thrust = thruster.thrust;
    dvMag = norm(dVVectECI);
    massFlowRate = getMdotFromThrustIsp(thrust, isp);
    burnDur = getBurnDuration(mass0, massFlowRate, isp, dvMag);
    
    if(burnDur == 0)
        eventLog = initialState;
        eventLog(13) = eventNum;
        return;
    end
    
    dVVectECI = reshape(dVVectECI,3,1);
    rhs = @(t,x) propBurnRHS(t, x, gmu, massFlowRate, dVVectECI, thrust);
    tspan = [ut, ut + burnDur];
    x0 = [rVectUT, vVectUT, mass0];
    options = odeset('RelTol',1E-6,'AbsTol',1E-6);
    [T,Y] = ode45(rhs,tspan,x0,options);
    
    dM = mass0 - Y(:,7);
    
    eventLog = zeros(length(T), length(initialState));
    eventLog(:,1) = T;
    eventLog(:,2:7) = Y(:,1:6);
    eventLog(:,8) = bodyID;
    eventLog(:,9) = initialState(9);
    eventLog(:,13) = eventNum;
    switch(thruster.propType)
        case 'fuelOxMass'
            eventLog(:,10) = initialState(10) - dM;
            eventLog(:,11) = initialState(11);
            eventLog(:,12) = initialState(12);
        case 'monoMass'
            eventLog(:,10) = initialState(10);
            eventLog(:,11) = initialState(11) - dM;
            eventLog(:,12) = initialState(12);
        case 'xenonMass'
            eventLog(:,10) = initialState(10);
            eventLog(:,11) = initialState(11);
            eventLog(:,12) = initialState(12) - dM;
    end 

end

function xdot = propBurnRHS(~, x, gmu, massFlowRate, dVVectECI, thrust)
    rVect = x(1:3);
    r = norm(rVect);
    vVect = x(4:6);
    m = x(7);
    
    gAccel = -(gmu/r^3)*rVect; %km^3/s^2 / km^2 = km/s^2
    
    dvNorm = normVector(dVVectECI);
    tForce = (thrust * dvNorm)/1000; %kN = tons * m/s^2/1000 = km/s^2
    
    try
    xdot(1:3) = vVect;
    xdot(4:6) = gAccel + tForce/m;
    xdot(7) = -massFlowRate;
    catch ME
        a =1;
    end
    
    xdot = xdot';
end