function [dragAccel, dragForce] = getDragAccel(bodyInfo, ut, rVectECI, vVectECI, dragCoeff, mass, dragModel)
%getDragAccel Summary of this function goes here
%   Detailed explanation goes here

    rVectECI = reshape(rVectECI,3,1);
    vVectECI = reshape(vVectECI,3,1);

    [lat, ~, altitude] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
    density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat); 
    
    surfVel = getSurfaceVelocity(bodyInfo, ut, rVectECI, vVectECI);
    surfVelMag = norm(surfVel);
    
    if(strcmpi(dragModel,'Stock'))
        CdA = dragCoeff; %m^2
    elseif(strcmpi(dragModel,'FAR') || strcmpi(dragModel,'NEAR'))
        CdA = dragCoeff; %m^2
    else
        error(['Invalid drag model in aerobraking calculations: ', dragModel]);
    end
    
    Fd = -(1/2) * density * (surfVelMag^2) * CdA; %kg/m^3 * (km^2/s^2) * m^2 = kg/m * km^2/s^2 = kg*(km/m)*km/s^2 = kg*(1000)*km/s^2
    dragAccelMag = Fd/mass; % (1000)*kg*km/s^2/kg/1000 = 1000*km/s^2/1000 = km/s^2
    dragAccel = dragAccelMag * normVector(vVectECI);
    dragForce = Fd * normVector(vVectECI);
end

