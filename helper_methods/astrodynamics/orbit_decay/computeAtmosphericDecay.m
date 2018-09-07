function [smaArr, eccArr, meanArr] = computeAtmosphericDecay(UTs, smaArr, eccArr, meanArr, bodyInfo, vesselMass, vesselArea, f107Flux, geomagneticIndex)
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
    density0 = getAtmoDensityAtAltitude(bodyInfo, 0.99*bodyInfo.atmohgt, 0);
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
    
    
    
%     [finalSma, finalEcc, finalTru] = computeAtmoDecayOneIteration(UTs, sma, ecc, tru, bodyInfo, vesselMass, vesselArea, f107Flux, geomagneticIndex);
end

% function [finalSma, finalEcc, finalTru] = computeAtmoDecayOneIteration(UTs, sma, ecc, tru, bodyInfo, vesselMass, vesselArea, f107Flux, geomagneticIndex)
%     timeDiffFromStart = UTs(2:end) - UTs(1);
%     timeDiffs = diff(UTs);    
%     
%     finalSma(1) = sma(1);
%     finalEcc(1) = ecc(1);
%     
%     sma0 = sma(1);
%     ecc0 = ecc(1);
%     tru0 = tru(1);
% 
%     meanA0 = computeMeanFromTrueAnom(tru0, ecc0);
%     
%     sma = sma(2:end);
%     ecc = ecc(2:end);
%     tru = tru(2:end);
%     
%     smaMeter = sma * 1000; %m
%     radius = computeRadiusFromTrueAEcc(tru, sma, ecc); %km
%     altitude = radius - bodyInfo.radius; %km
%     
%     altitude(altitude < 0) = 0; %km
%     altitude = 1000 * altitude; %km -> m;
%     
%     refAlt = 1000 * (0.99*bodyInfo.atmohgt); %m
%     
% 
%     
%     densityRefAlt = getAtmoDensityAtAltitude(bodyInfo, refAlt/1000, 0); %kg/m^3
%     density = densityRefAlt .* exp(-(altitude-refAlt)./scaleHeight); %kg/m^3
%     
%     Cd = 2.2;
%     
%     initPeriod = computePeriod(sma, bodyInfo.gm);
%     
%     dpDt = -3*pi.*smaMeter.*density.*((vesselArea.*Cd)./vesselMass); %sec/sec????
%     dP = cumsum(dpDt.*timeDiffs); %sec
%     
%     finalPeriod = initPeriod + dP;
%     finalPeriodLessThanZero = finalPeriod<0;
%     finalPeriod(finalPeriodLessThanZero) = eps;
%     
% %     daDt = -computeSMAFromPeriod(abs(dpDt), bodyInfo.gm);
%     
%     finalEccEnd = ecc;
%     
% %     dEccDt = finalEccEnd.*(1-finalEccEnd.^2) .* daDt/sma0;
% %     dEcc = dEccDt .* timeDiffFromStart;
% %     finalEccEnd = finalEccEnd + dEcc; 
% %     finalEccEnd(finalEccEnd<0) = 0;
%     
%     finalSmaEnd = computeSMAFromPeriod(finalPeriod, bodyInfo.gm);
%     
% 
%     finalMeanMotions = computeMeanMotion(finalSmaEnd, bodyInfo.gm);
%     finalMeanAnoms = AngleZero2Pi(meanA0 + cumsum(finalMeanMotions.*timeDiffs));
%     
%     finalSma = horzcat(finalSma,finalSmaEnd);
%     finalEcc = horzcat(finalEcc,finalEccEnd);
%     
%     finalTruEnd = zeros(size(finalEccEnd));
%     finalMeanA = finalMeanAnoms;
%     notFinalPeriodLessThanZero = not(finalPeriodLessThanZero);
%     finalTruEnd(not(finalPeriodLessThanZero)) = computeTrueAnomFromMean(finalMeanA(notFinalPeriodLessThanZero), finalEcc(notFinalPeriodLessThanZero));
%     
%     finalTru = horzcat(meanA0,finalTruEnd);
% end
% 
