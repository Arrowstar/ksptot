function twRatio = computeTrueThrustToWeight(bodyInfo, totalThrust, totalMass, altitude)    
    %thrust must be in Newtons and mass must be in kg!
    
    gSlAccel = (bodyInfo.gm / ((bodyInfo.radius+altitude)^2))*1000; %m/s^2
    totalSlWeight = totalMass*gSlAccel; %kg*m/s^2 = N

    twRatio = totalThrust/totalSlWeight;
end