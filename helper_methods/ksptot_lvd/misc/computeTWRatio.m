function twRatio = computeTWRatio(throttle, ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo)
    altitude = norm(rVect) - bodyInfo.radius;
    presskPa = getPressureAtAltitude(bodyInfo, altitude); 

    [~, totalThrust]= LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankMasses, stgStates, throttle, lvState, presskPa, ut, rVect, vVect, bodyInfo, []);

    totalMass = (dryMass + sum(tankMasses))*1000; %kg          
    totalThrust = totalThrust * 1000; % N

%     twRatio = computeSLThrustToWeight(bodyInfo, totalThrust, totalMass);
    twRatio = computeTrueThrustToWeight(bodyInfo, totalThrust, totalMass, altitude);
end