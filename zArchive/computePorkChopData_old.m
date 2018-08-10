function [departDV, arrivalDV, totalDV, departTimeArr, arrivalTimeArr] = computePorkChopData(celBodyData, departBody, earlyDepartTime, arrivalBody, earlyArrivalTime, gmu, options)
%computePorkChopData Summary of this function goes here
%   Detailed explanation goes here
    axesResPts = options.porkchopPtsAxes;
    numSynPeriods = options.porkchopNumSynPeriods;

    departBody = lower(departBody);
    departBodyInfo = celBodyData.(departBody);
    departBodyMeanMotion = computeMeanMotion(departBodyInfo.sma, gmu);
    
    arrivalBody = lower(arrivalBody);
    arrivalBodyInfo = celBodyData.(arrivalBody);
    arrivalBodyMeanMotion = computeMeanMotion(arrivalBodyInfo.sma, gmu);

    synPeriod = computeSynodicPeriod(departBodyMeanMotion, arrivalBodyMeanMotion);
    
    departTimeArr = linspace(earlyDepartTime, earlyDepartTime+numSynPeriods*synPeriod, axesResPts);
    arrivalTimeArr = linspace(earlyArrivalTime, earlyArrivalTime+numSynPeriods*synPeriod, axesResPts);
    
    departDV = zeros(length(departTimeArr), length(arrivalTimeArr));
    arrivalDV = zeros(length(departTimeArr), length(arrivalTimeArr));
    totalDV = zeros(length(departTimeArr), length(arrivalTimeArr));
    
%     [rVectD, vVectDBody] = getStateAtTime(departBodyInfo, departTimeArr, gmu);
%     [rVectA, vVectABody] = getStateAtTime(arrivalBodyInfo, arrivalTimeArr, gmu);
%     timeOfFlight = bsxfun(@minus, arrivalTimeArr.',departTimeArr);
% 
%     timeOfFlightReshape = reshape(timeOfFlight,numel(timeOfFlight),1)';
%     rVectARep = repmat(rVectA,1,length(departTimeArr));
%     rVectDRep = reshape(repmat(rVectD,length(arrivalTimeArr),1),3,size(rVectARep,2));
%     
%     vVectARepBody = repmat(vVectABody,1,length(departTimeArr));
%     vVectDRepBody = reshape(repmat(vVectDBody,length(arrivalTimeArr),1),3,size(vVectARepBody,2));
%     
%     gmuRepMat = gmu * ones(size(timeOfFlightReshape));
%     [departVelocity1, arrivalVelocity1] = lambertBattinVector(rVectDRep, rVectARep, timeOfFlightReshape, 0, gmuRepMat);
%     [departVelocity2, arrivalVelocity2] = lambertBattinVector(rVectDRep, rVectARep, -1*timeOfFlightReshape, 0, gmuRepMat);
%     
%     dvD1 = departVelocity1 - vVectDRepBody;
%     dvD1Mag = sqrt(sum(abs(dvD1).^2,1));
%     departDV1 = reshape(dvD1Mag,size(departDV));
%     
%     dvA1 = arrivalVelocity1 - vVectARepBody;
%     dvA1Mag = sqrt(sum(abs(dvA1).^2,1));
%     arrivalDV1 = reshape(dvA1Mag,size(arrivalDV));
%     
%     dvD2 = departVelocity2 - vVectDRepBody;
%     dvD2Mag = sqrt(sum(abs(dvD2).^2,1));
%     departDV2 = reshape(dvD2Mag,size(departDV));
%     
%     dvA2 = arrivalVelocity2 - vVectARepBody;
%     dvA2Mag = sqrt(sum(abs(dvA2).^2,1));
%     arrivalDV2 = reshape(dvA2Mag,size(arrivalDV));
%     
%     departDV = bsxfun(@min,departDV1,departDV2)';
%     arrivalDV = bsxfun(@min,arrivalDV1,arrivalDV2)';
%     totalDV = bsxfun(@min ,departDV1 + arrivalDV1, departDV2 + arrivalDV2)';
%     
%     timeOfFlight(timeOfFlight<=0) = NaN;
%     negDtInds = find(isnan(timeOfFlight));
%     departDV(negDtInds) = NaN;
%     arrivalDV(negDtInds) = NaN;
%     totalDV(negDtInds) = NaN;
    

    hWaitBar = waitbar(0,'Computing Porkchop Plot...'); 
    totalSteps = length(departTimeArr)*length(arrivalTimeArr);
    
    step=0;
    ticID = tic();
    
    for(i=1:length(departTimeArr)) %#ok<*NO4LP>
        for(j=1:length(arrivalTimeArr))
            departTime = departTimeArr(i);
            arrivalTime = arrivalTimeArr(j);
            timeOfFlight = (arrivalTime - departTime)/(86400);
            
            step=step+1;
%             waitbar(step/totalSteps, hWaitBar, ['Computing Porkchop Plot... ', num2str(step/totalSteps*100), '% [', num2str(elapsedTime) ' sec]'  ]);
            optimValues.localrunindex=step;
            msOutFcn(optimValues, [], totalSteps, hWaitBar, 'Computing Porkchop Plot...', ticID);         

            if(timeOfFlight > 0)
                [rVecD, vVecDBody] = getStateAtTime(departBodyInfo, departTime, gmu);
                [rVecA, vVecABody] = getStateAtTime(arrivalBodyInfo, arrivalTime, gmu);
                
                numRevs=0;
                
                %Type 1 Orbits (compute depart/arrive dv)
                [departVelocity,arrivalVelocity]=lambert(rVecD', rVecA', 1*timeOfFlight, numRevs, gmu);
                departVelocity = correctNaNInVelVect(departVelocity);
                arrivalVelocity = correctNaNInVelVect(arrivalVelocity);
                departDVT1 = norm(departVelocity' - vVecDBody);
                arrivalDVT1 = norm(arrivalVelocity' - vVecABody);
                totalDVT1 = departDVT1 + arrivalDVT1;
                
                %Type 2 Orbits (compute depart/arrive dv)
                [departVelocity,arrivalVelocity]=lambert(rVecD', rVecA', -1*timeOfFlight, numRevs, gmu);
                departVelocity = correctNaNInVelVect(departVelocity);
                arrivalVelocity = correctNaNInVelVect(arrivalVelocity);
                departDVT2 = norm(departVelocity' - vVecDBody);
                arrivalDVT2 = norm(arrivalVelocity' - vVecABody);
                totalDVT2 = departDVT2 + arrivalDVT2;
                
                %Populate Arrays
                departDV(i,j) = min(departDVT1,departDVT2);
                arrivalDV(i,j) = min(arrivalDVT1,arrivalDVT2);
                totalDV(i,j) = min(totalDVT1, totalDVT2);
            else 
                departDV(i,j) = NaN;
                arrivalDV(i,j) = NaN;
                totalDV(i,j) = NaN;
            end
        end
    end

    close(hWaitBar);
end

