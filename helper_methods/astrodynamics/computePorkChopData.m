function [departDV, arrivalDV, totalDV, departTimeArr, arrivalTimeArr, numSynPeriods] = computePorkChopData(celBodyData, departBody, earlyDepartTime, arrivalBody, earlyArrivalTime, gmu, options)
%computePorkChopData Summary of this function goes here
%   Detailed explanation goes here
    axesResPts = options.porkchopptsaxes;
    numSynPeriods = options.porkchopnumsynperiods;

    departBody = lower(departBody);
    departBodyInfo = celBodyData.(departBody);
    departBodyMeanMotion = computeMeanMotion(departBodyInfo.sma, gmu);
    
    arrivalBody = lower(arrivalBody);
    arrivalBodyInfo = celBodyData.(arrivalBody);
    arrivalBodyMeanMotion = computeMeanMotion(arrivalBodyInfo.sma, gmu);

    synPeriod = computeSynodicPeriod(departBodyMeanMotion, arrivalBodyMeanMotion);

    testSMA = (departBodyInfo.sma + arrivalBodyInfo.sma)/2;
    testPeriod = computePeriod(testSMA, getParentGM(departBodyInfo, celBodyData));
    
    if(numSynPeriods*synPeriod < 0.5 * testPeriod)
        testNewSynPeriods = ceil(testPeriod / synPeriod);
        button = questdlg(sprintf('Your selected number of synodic periods (in Options menu) may be too small.  %i may be a more appropriate number of synodic periods (current value = %i).  Would you like to try this?  This will permanently update the set value in your Options.',testNewSynPeriods, numSynPeriods),'Update number of synodic periods value?','Yes','No','Yes');
        
        if(strcmpi(button,'Yes'))
            numSynPeriods = testNewSynPeriods;
        end
    end
    
    departTimeArr = linspace(earlyDepartTime, earlyDepartTime+numSynPeriods*synPeriod, axesResPts);
    arrivalTimeArr = linspace(earlyArrivalTime, earlyArrivalTime+numSynPeriods*synPeriod, axesResPts);
    
%     departDV = zeros(length(departTimeArr), length(arrivalTimeArr));
%     arrivalDV = zeros(length(departTimeArr), length(arrivalTimeArr));
%     totalDV = zeros(length(departTimeArr), length(arrivalTimeArr));
    
    hWaitBar = waitbar(0,'Computing Porkchop Plot...'); 
%     totalSteps = length(departTimeArr)*length(arrivalTimeArr);
    
    step=0;
    
    % Use vectorized lambert solver?
    if (true)
        % Vectorized Lambert solver

        % Get the departure and arrival body position and velocity vectors
        rVecD       = zeros(1,3,axesResPts);
        vVecDBody   = zeros(1,3,axesResPts);
        rVecA       = zeros(1,3,axesResPts);
        vVecABody   = zeros(1,3,axesResPts);
        for i=1:axesResPts
            [rVecD(:,:,i,1), vVecDBody(:,:,i,1)] = getStateAtTime(departBodyInfo,  departTimeArr(i),  gmu);
            [rVecA(:,:,1,i), vVecABody(:,:,1,i)] = getStateAtTime(arrivalBodyInfo, arrivalTimeArr(i), gmu);
        end

        % Repeat the vectors to create meshgrids
        % This creates 4D matrices.
        % dim(1) is singleton
        % dim(2) varies the components of vectors, or is singleton
        % dim(3) varies the daprture time
        % dim(4) varies the arrival time
        
        % Repeat along the 4th dimension
        rVecD       = rVecD    (:,:,:,ones(1,axesResPts));
        vVecDBody   = vVecDBody(:,:,:,ones(1,axesResPts));
        
        % Repeat along the 3rd dimension
        rVecA       = rVecA    (:,:,ones(1,axesResPts),:);
        vVecABody   = vVecABody(:,:,ones(1,axesResPts),:);

        % Time of Flight is in Earth days
        timeOfFlight = reshape(bsxfun(@minus,arrivalTimeArr,departTimeArr'), 1,1,axesResPts,axesResPts)/(86400);
        timeOfFlight(timeOfFlight<0) = 0; % Zero out flight time for any impossible combinations

        gmu = ones([1 1 axesResPts axesResPts]) * gmu;

        % Compute Lambert solutions in the forward direction
        [departVelocity, arrivalVelocity] = lambert_vector(rVecD, rVecA, timeOfFlight, 0, gmu);
        waitbar(0.5,hWaitBar);
        
        % Any velocities that are NaN, put at infinite 
        departVelocity(isnan(departVelocity)) = inf;
        arrivalVelocity(isnan(arrivalVelocity)) = inf;

        % Compute departure and arrival delta-V
        departDVT1  = departVelocity - vVecDBody;
        departDVT1  = sqrt(mtimesx(departDVT1,  departDVT1, 'T'));
        departDVT1(timeOfFlight <= 0) = NaN;
        arrivalDVT1 = arrivalVelocity - vVecABody;
        arrivalDVT1 = sqrt(mtimesx(arrivalDVT1, arrivalDVT1,'T'));
        arrivalDVT1(timeOfFlight <= 0) = NaN;
        totalDVT1   = departDVT1 + arrivalDVT1;

        % Compute Lambert solutions in the backward direction
        [departVelocity, arrivalVelocity] = lambert_vector(rVecD, rVecA, -timeOfFlight, 0, gmu);

        % Any velocities that are NaN, put at infinite 
        departVelocity(isnan(departVelocity)) = inf;
        arrivalVelocity(isnan(arrivalVelocity)) = inf;

        % Compute departure and arrival delta-V
        departDVT2  = departVelocity - vVecDBody;
        departDVT2  = sqrt(mtimesx(departDVT2,  departDVT2, 'T'));
        departDVT2(timeOfFlight <= 0) = NaN;
        arrivalDVT2 = arrivalVelocity - vVecABody;
        arrivalDVT2 = sqrt(mtimesx(arrivalDVT2, arrivalDVT2,'T'));
        arrivalDVT2(timeOfFlight <= 0) = NaN;
        totalDVT2   = departDVT2 + arrivalDVT2;

        departDV  = squeeze(bsxfun(@min, departDVT1,  departDVT2 ));
        arrivalDV = squeeze(bsxfun(@min, arrivalDVT1, arrivalDVT2));
        totalDV   = squeeze(bsxfun(@min, totalDVT1,   totalDVT2  ));
        waitbar(1.0,hWaitBar);
    else
        % Linear lambert solver
        
        rVecD = []; vVecDBody = [];
        rVecA = []; vVecABody = [];
        gmu = gmu(1,1,1,1);

        ticID = tic();

        for(i=1:length(departTimeArr)) %#ok<*NO4LP>
            for(j=1:length(arrivalTimeArr))
                departTime = departTimeArr(i);
                arrivalTime = arrivalTimeArr(j);
                timeOfFlight = (arrivalTime - departTime)/(86400); % Time of Flight is in Earth days

                step=step+1;
    %             waitbar(step/totalSteps, hWaitBar, ['Computing Porkchop Plot... ', num2str(step/totalSteps*100), '% [', num2str(elapsedTime) ' sec]'  ]);
                optimValues.localrunindex=step;
                msOutFcn(optimValues, [], totalSteps, hWaitBar, 'Computing Porkchop Plot...', ticID);         

                if(timeOfFlight > 0)
                    [rVecD, vVecDBody] = getStateAtTime(departBodyInfo, departTime, gmu);
                    [rVecA, vVecABody] = getStateAtTime(arrivalBodyInfo, arrivalTime, gmu);

                    numRevs=0;

                    %Type 1 Orbits (compute depart/arrive dv)
                    [departVelocity,arrivalVelocity]=orbit.lambert(rVecD', rVecA', +1*timeOfFlight, numRevs, gmu);
                    departVelocity = correctNaNInVelVect(departVelocity);
                    arrivalVelocity = correctNaNInVelVect(arrivalVelocity);
                    departDVT1 = norm(departVelocity' - vVecDBody);
                    arrivalDVT1 = norm(arrivalVelocity' - vVecABody);
                    totalDVT1 = departDVT1 + arrivalDVT1;

                    %Type 2 Orbits (compute depart/arrive dv)
                    [departVelocity,arrivalVelocity]=orbit.lambert(rVecD', rVecA', -1*timeOfFlight, numRevs, gmu);
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

        toc(ticID);
    end
    
    close(hWaitBar);
end

