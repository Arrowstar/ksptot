function aeroDvVect = getAerobrakeDeltaV(bodyInfo, ut, rVectECI, vVectECI, dragCoeff, mass, dragModel)
%getAerobrakeDeltaV Summary of this function goes here
%   Detailed explanation goes here
    rVectECI = reshape(rVectECI,3,1);
    vVectECI = reshape(vVectECI,3,1);

    [lat, ~, altitude] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
    density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat); %kg/m^3
    surfVel = getSurfaceVelocity(bodyInfo, ut, rVectECI, vVectECI);
    surfVelMag = norm(surfVel);
   
    gmu = bodyInfo.gm;
    [sma, ecc, ~, ~, ~, ~] = getKeplerFromState(rVectECI,vVectECI,gmu);
    [~, rPe] = computeApogeePerigee(sma, ecc);
    
    mass = 1000 * mass; %metric ton -> kg
    
    %balCoeff = Cd*A/(m*2)
    if(strcmpi(dragModel,'Stock'))
        %But in KSP, A = 0.008*mass
        %So balCoeff = (Cd*0.008*m)/(2*m) = 0.004*Cd
        balCoeff = 0.004*dragCoeff;
    elseif(strcmpi(dragModel,'FAR'))
        %In FAR/NEAR, we'll treat Cd as Cd*A
        balCoeff = dragCoeff / (mass * 2);
    elseif(strcmpi(dragModel,'NEAR'))
        %In FAR/NEAR, we'll treat Cd as Cd*A
        balCoeff = dragCoeff / (mass * 2);
    else
        error(['Invalid drag model in aerobraking DV calculations: ', dragModel]);
    end
    
    dvMag1 = balCoeff * density * surfVelMag^2 * rPe; %m^2/kg * kg/m^3 * (km^2/s^2) * km = km/m * (km^2/s^2)
    dvMag2 = sqrt((2*pi)/gmu); %s/km^(3/2)
    dvMag3 = 1/sqrt(ecc); %dimless
    dvMag4 = sqrt(bodyInfo.atmoscalehgt); %km^(1/2)
    
    %dvMag2*dvMag4 = %s/km^(3/2) * km^(1/2) = s/km
    %dvMag2*dvMag4*dvMag1 = km/m * (km/s) = 1000 * km/s <-----------ANSWER
    
    dvMag = dvMag1 * dvMag2 * dvMag3 * dvMag4;
    aeroDvVect = -normVector(vVectECI) * dvMag * 1000;
    
    %need to prevent drag from shooting you off into space the other way!
    if(norm(aeroDvVect) > norm(vVectECI))
        aeroDvVect = (-vVectECI)*0.99;
    end
end

