function [aDot, eDot, argDot] = getAtmosDragElementDerivs(sma, ecc, eccAnom, gmu, density0, R, Cd, area, mass, atmomolarmass, f107Flux, geomagneticIndex)
    %Source: http://farside.ph.utexas.edu/teaching/celestial/Celestialhtml/node94.html
    
    a = sma;
    e = ecc;
    E = eccAnom;
    A = area;
    rho0 = density0;
    m = mass;
    n = sqrt(gmu/sma^3);
    
    r = a*(1-e*cos(E));
    
    g =  gmu ./ r.^2; 
    gasConstant = getIdealGasConstant();
    molecularMass = atmomolarmass; 
    exothericTemperature = 900.0 + 2.5 * (f107Flux - 70.0) + 1.5 * geomagneticIndex; %K
    H = (gasConstant.*exothericTemperature) ./ (molecularMass.*g); %m
    
    alpha = -(r - R)/H;
    rho = rho0*exp(alpha);
    
    aDotOverA = -(Cd*A*a*rho/m)*n*((1+e*cos(E))^(3/2) / (1-e*cos(E))^(3/2));
    aDot = aDotOverA * a;
    
    if(e > 0)
        eDot = -(Cd*A*a*rho/m)*n*(1-e^2)*((1+e*cos(E))^(1/2) / (1-e*cos(E))^(3/2))*cos(E);
    else
        eDot = 0; %can't go less than circular
    end
    
    if(e > 0)
        argDot = -(Cd*A*a*rho/m)*n*((1-e^2)^(1/2) / e)*((1+e*cos(E))^(1/2) / (1-e*cos(E))^(3/2))*sin(E);
    else
        argDot = 0; %if circular, then there is no arg of periapsis
    end
end