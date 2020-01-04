function [smaArr, eccArr, meanArr] = computeAtmosphericDecay(UTs, smaArr, eccArr, meanArr, bodyInfo, vesselMass, vesselArea, f107Flux, geomagneticIndex, celBodyData)
    %computeAtmosphericDecay Summary of this function goes here
    %   Detailed explanation goes here  
    
    %vesselMass must be in kg!
    %vesselArea must be in m^2
    
    if(bodyInfo.atmohgt == 0 || length(smaArr) <= 1)
        
        return;
    end
     
    gmu = bodyInfo.gm * (1000^3); %km^3/s2 -> m^3/s2
    R = (bodyInfo.radius + 0.99*bodyInfo.atmohgt) * 1000; %km -> m
    vesselMass = vesselMass * 1000; %mT -> kg
    density0 = getAtmoDensityAtAltitude(bodyInfo, 0.99*bodyInfo.atmohgt, 0, 0, [bodyInfo.atmohgt.radius + 0.99*bodyInfo.atmohgt;0;0], celBodyData);
    for(i=1:length(UTs)-1) %#ok<NO4LP>
        sma = smaArr(i) * 1000; %km -> m
        ecc = eccArr(i);
        meanA = meanArr(i);
        
        eccA = solveKepler(meanA, ecc);
        
        [aDot, eDot, ~] = getAtmosDragElementDerivs(sma, ecc, eccA, gmu, density0, R, 2.2, vesselArea, vesselMass, bodyInfo.atmomolarmass, f107Flux, geomagneticIndex);
        
        dt = (UTs(i+1) - UTs(i));
        
        %max functions so we don't go below zero on SMA or ecc, which
        %should never happen
        smaArr(i+1) = max(sma + aDot*dt, 0)/1000; %m -> km
        eccArr(i+1) = max(ecc + eDot*dt, 0);
    end
end