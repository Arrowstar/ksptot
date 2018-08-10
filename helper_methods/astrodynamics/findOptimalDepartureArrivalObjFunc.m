function [deltaV2Report, departHypExVelVect] = findOptimalDepartureArrivalObjFunc(arrivalTime, departTime, departBodyInfo, arrivalBodyInfo, gmu, quant2Opt, numRevs)
%findOptimalArrivalObjFunc Summary of this function goes here
%   Detailed explanation goes here

    [rVecD, vVecDBody] = getStateAtTime(departBodyInfo, departTime, gmu);
    [rVecA, vVecABody] = getStateAtTime(arrivalBodyInfo, arrivalTime, gmu);

%     numRevs=0;
    
    timeOfFlight = (arrivalTime - departTime)/(86400);

    %Type 1 Orbits (compute depart/arrive dv)
    [departVelocity,arrivalVelocity]=lambert(rVecD', rVecA', 1*timeOfFlight, numRevs, gmu);
    departVelocity = correctNaNInVelVect(departVelocity);
    arrivalVelocity = correctNaNInVelVect(arrivalVelocity);
    departHypExVelVectDVT1 = departVelocity' - vVecDBody;
    departDVT1 = norm(departVelocity' - vVecDBody);
    arrivalDVT1 = norm(arrivalVelocity' - vVecABody);
    totalDVT1 = departDVT1 + arrivalDVT1;

    %Type 2 Orbits (compute depart/arrive dv)
    [departVelocity,arrivalVelocity]=lambert(rVecD', rVecA', -1*timeOfFlight, numRevs, gmu);
    departVelocity = correctNaNInVelVect(departVelocity);
    arrivalVelocity = correctNaNInVelVect(arrivalVelocity);
    departHypExVelVectDVT2 = departVelocity' - vVecDBody;
    departDVT2 = norm(departVelocity' - vVecDBody);
    arrivalDVT2 = norm(arrivalVelocity' - vVecABody);
    totalDVT2 = departDVT2 + arrivalDVT2;
    
    switch(quant2Opt)
        case 'departDVRadioBtn'
            deltaV2Report = min(departDVT1, departDVT2);
            if(deltaV2Report == departDVT1)
                departHypExVelVect = departHypExVelVectDVT1;
            elseif(deltaV2Report == departDVT2)
                departHypExVelVect = departHypExVelVectDVT2;
            end
        case 'arrivalDVRadioBtn'
            deltaV2Report = min(arrivalDVT1, arrivalDVT2);
            if(deltaV2Report == arrivalDVT1)
                departHypExVelVect = departHypExVelVectDVT1;
            elseif(deltaV2Report == arrivalDVT2)
                departHypExVelVect = departHypExVelVectDVT2;
            end
        case 'departPArrivalDVRadioBtn'
            deltaV2Report = min(totalDVT1, totalDVT2);
            if(deltaV2Report == totalDVT1)
                departHypExVelVect = departHypExVelVectDVT1;
            elseif(deltaV2Report == totalDVT2)
                departHypExVelVect = departHypExVelVectDVT2;
            end
        otherwise
            deltaV2Report = min(totalDVT1, totalDVT2);
            if(deltaV2Report == totalDVT1)
                departHypExVelVect = departHypExVelVectDVT1;
            elseif(deltaV2Report == totalDVT2)
                departHypExVelVect = departHypExVelVectDVT2;
            end
    end
 
    if(isnan(deltaV2Report))
        deltaV2Report=1E25;
    end
end

