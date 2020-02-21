function hDepartDisp = computeDeparture(celBodyData, departBody, arrivalBody, departUT, arrivalUT, eSMA, eEcc, eInc, eRAAN, eArg, gmuXfr, cBody, options, eMA, eEpoch)
    gmuDepartBody = celBodyData.(lower(departBody)).gm;
    timeOfFlight = (arrivalUT - departUT)/(86400);
    numRevs=0;

    centralBodyInfo = celBodyData.(cBody);
    centralBodyFrame = centralBodyInfo.getBodyCenteredInertialFrame();
    departBodyInfo = celBodyData.(departBody);
    departBodyFrame = departBodyInfo.getBodyCenteredInertialFrame();
    arriveBodyInfo = celBodyData.(arrivalBody);
    
    [rVecD, vVecDBody] = getStateAtTime(departBodyInfo, departUT, gmuXfr);
    [rVecA, vVecABody] = getStateAtTime(arriveBodyInfo, arrivalUT, gmuXfr);

    %Type 1 Orbits (compute depart/arrive dv)
    [departVelocity,arrivalVelocity]=lambert(rVecD', rVecA', 1*timeOfFlight, numRevs, gmuXfr);
    departVelocity = correctNaNInVelVect(departVelocity);
    arrivalVelocity = correctNaNInVelVect(arrivalVelocity);
    departStateXfrBody = CartesianElementSet(departUT,rVecD,departVelocity(:),centralBodyFrame);
    departStateDepartBody = departStateXfrBody.convertToFrame(departBodyFrame);
    departDVT1 = norm(departVelocity' - vVecDBody);
    arrivalDVT1 = norm(arrivalVelocity' - vVecABody);
    totalDVT1 = departDVT1 + arrivalDVT1;
    hyperExcessVelDepT1 = departStateDepartBody.vVect;
    arrivalVelocity1 = arrivalVelocity;
    rVecA1 = rVecA;
    departVelocity1 = departVelocity;
    rVecD1 = rVecD;
    
    %Type 2 Orbits (compute depart/arrive dv)
    [departVelocity,arrivalVelocity]=lambert(rVecD', rVecA', -1*timeOfFlight, numRevs, gmuXfr);
    departVelocity = correctNaNInVelVect(departVelocity);
    arrivalVelocity = correctNaNInVelVect(arrivalVelocity);
    departStateXfrBody = CartesianElementSet(departUT,rVecD,departVelocity(:),centralBodyFrame);
    departStateDepartBody = departStateXfrBody.convertToFrame(departBodyFrame);
    departDVT2 = norm(departVelocity' - vVecDBody);
    arrivalDVT2 = norm(arrivalVelocity' - vVecABody);
    totalDVT2 = departDVT2 + arrivalDVT2;
    hyperExcessVelDepT2 = departStateDepartBody.vVect; % departVelocity' - vVecDBody;
    arrivalVelocity2 = arrivalVelocity;
    rVecA2 = rVecA;
    departVelocity2 = departVelocity;
    rVecD2 = rVecD;

    if(totalDVT1 < totalDVT2)
        hVInf = hyperExcessVelDepT1;
        arrivalVelocity = arrivalVelocity1;
        rVecA = rVecA1;
        rVecD = rVecD1;
        departVelocity = departVelocity1;
    else 
        hVInf = hyperExcessVelDepT2;
        arrivalVelocity = arrivalVelocity2;
        rVecA = rVecA2;
        rVecD = rVecD2;
        departVelocity = departVelocity2;
    end
    [smaX, eccX, incX, raanX, argX, anomAX] = getKeplerFromState(rVecA,arrivalVelocity,gmuXfr);
    [~, ~, ~, ~, ~, anomDX] = getKeplerFromState(rVecD,departVelocity,gmuXfr);
   
    bodyInfo = celBodyData.(lower(departBody));
    parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
    rSOI = getSOIRadius(celBodyData.(lower(departBody)), parentBodyInfo)*1.0;
    if(eEcc < 1.0)
        iniLB = 0;
        iniUB = 2*pi;
        x0 = pi;
        plotBnds = [iniLB iniUB];
    else
        if(rSOI > 5*celBodyData.(lower(departBody)).radius) 
            maxPlotR = 5*celBodyData.(lower(departBody)).radius;
        else
            maxPlotR = rSOI;
        end
                
        iniHyTruMax = AngleZero2Pi(computeTrueAFromRadiusEcc(rSOI, eSMA, eEcc));
        iniLB = -iniHyTruMax;
        iniUB = iniHyTruMax;
        x0 = 0.0;
        
        plotBnds = [-AngleZero2Pi(computeTrueAFromRadiusEcc(maxPlotR, eSMA, eEcc)) AngleZero2Pi(computeTrueAFromRadiusEcc(maxPlotR, eSMA, eEcc))];
    end
    
    [dVVect, dVVectNTW, eRVect, hOrbit, eTA] = computeDepartureOrbit(eSMA, eEcc, eInc, eRAAN, eArg, eMA, eEpoch, gmuDepartBody, hVInf, departUT, arrivalUT, options.departplotnumoptiters, x0, iniLB, iniUB, departBody, arrivalBody, 0, parentBodyInfo, celBodyData);
    
%     ePeriod = computePeriod(eSMA, gmuDepartBody);
%     meanMotion = computeMeanMotion(eSMA, gmuDepartBody);
%     if(not(isempty(eMA) && isempty(eEpoch)))
%         curMean = AngleZero2Pi(meanMotion*(departUT-eEpoch)+eMA);
%     else
%         curMean = eMA;
%     end
%     
%     deltaT = 1;
%     while(abs(deltaT) > 0.1)
%         %Optimization set up
%         fun = @(x) computeDepartArriveDVFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, x, gmuDepartBody, hVInf);
%         nonlcon = @(x) hyperOrbitExcessVelConst(eSMA, eEcc, eInc, eRAAN, eArg, x, gmuDepartBody, hVInf, 1);
%         
%         %Optimization run
%         [eTA,~] = multiStartCommonRun('Searching for departure orbit...',...
%                                        options.departPlotNumOptIters,...
%                                        fun, x0, [], [], iniLB, iniUB, nonlcon);
%         
%         if(isempty(eMA) && isempty(eEpoch))
%             deltaT=0;
%         else
%             meanIdeal = AngleZero2Pi(computeMeanFromTrueAnom(eTA, eEcc));            
%             deltaT = (meanIdeal - curMean)/meanMotion;
%             curMean = AngleZero2Pi(curMean + meanMotion*deltaT);
%             departUT = departUT + deltaT;
%             if(deltaT < 0 && (departUT < eEpoch))
%                 departUT = departUT + ePeriod;
%             end
%             [~, hVInf] = findOptimalDepartureArrivalObjFunc(arrivalUT, departUT, celBodyData.(lower(departBody)), celBodyData.(arrivalBody), parentBodyInfo.gm, 'departPArrivalDVRadioBtn');
%         end
%     end
%           
%     %Using Optimization results
%     [~, dVVect, dVVectNTW, eRVect, hOrbit] = computeDepartArriveDVFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmuDepartBody, hVInf);
% %     [sUnitVector, OUnitVector] = hyperOrbitExcessVelConstMath(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmuDepartBody, hVInf);
   
    %Departure display
    [hDepartArr, hDepartDisp] = departDisplayGUI();
    departAxis = hDepartArr{1};
    hyperOrbitText = hDepartArr{2};
    mainOrbitText = hDepartArr{3};
    burnInfoText = hDepartArr{4}; 
    departDispGUI = hDepartArr{5};
    hyperOrbitLabel = hDepartArr{6};
    transOrbitLabel = hDepartArr{7};
    departureOrbitRadio = hDepartArr{8};
    
    %1337 plotting
    hSMA = hOrbit(1);
    hEcc = hOrbit(2);
    hInc = hOrbit(3);
    hRAAN = hOrbit(4);
    hArg = hOrbit(5);
%     hTA = hOrbit(6);

    [~, OUnitVector, vInfMag] = computeHyperSVectOVect(hSMA, hEcc, hInc, hRAAN, hArg, 0.0, gmuDepartBody);
    OUnitVector = normVector(OUnitVector);

    set(hyperOrbitLabel, 'String', [cap1stLetter(departBody),'-Centric Hyperbolic Departure Orbit']);
    set(departDispGUI, 'Name', [cap1stLetter(departBody),' Departure Information']);
    set(departureOrbitRadio, 'String', [cap1stLetter(lower(departBody)),' Departure Orbit']);
    
    [vInfRA,vInfDec,~] = cart2sph(OUnitVector(1),OUnitVector(2),OUnitVector(3));
    vInfRA = rad2deg(vInfRA);
    vInfDec = rad2deg(vInfDec);
    
    form = '%9.4f';
    form2 = '%2.9f';
    paddLen = 32;
    hyperOrbitText1 = ['Hyperbolic Departure Orbit from ', cap1stLetter(departBody)];
    hyperOrbitText1b = '---------------------------------------------';
    hyperOrbitText2 = [paddStr('Semi-major Axis = ',paddLen), num2str(hSMA, form), ' km'];
    hyperOrbitText3 = [paddStr('Eccentricity = ', paddLen), num2str(hEcc, form2)];
    hyperOrbitText4 = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(hInc)), form), ' deg'];
    hyperOrbitText5 = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(hRAAN)), form), ' deg'];
    hyperOrbitText6 = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(hArg)), form), ' deg'];
    hyperOrbitText7 = '---------------------';
    hyperOrbitText8 = [paddStr('Out. Hyp. Vel. Vect Rt. Asc. = ',paddLen), num2str(vInfRA, form), ' deg'];
    hyperOrbitText9 = [paddStr('Out. Hyp. Vel. Vect Declin. = ',paddLen), num2str(vInfDec, form), ' deg'];
    hyperOrbitText10 = [paddStr('Out. Hyp. Vel. Magnitude = ',paddLen), num2str(vInfMag, form2), ' km/s'];
    hyperOrbitTextstr = {hyperOrbitText1, hyperOrbitText1b, hyperOrbitText2, hyperOrbitText3, hyperOrbitText4, hyperOrbitText5, hyperOrbitText6, hyperOrbitText7, hyperOrbitText8, hyperOrbitText9, hyperOrbitText10};
    set(hyperOrbitText,'String',hyperOrbitTextstr);
    
    paddLen = 30;
    xferOrbitText1 = ['Transfer Orbit about ', cap1stLetter(cBody)];
    xferOrbitText11 = '---------------------------------------------';
    xferOrbitText2 = [paddStr('Semi-major Axis = ',paddLen), num2str(smaX, form), ' km'];
    xferOrbitText3 = [paddStr('Eccentricity = ', paddLen), num2str(eccX, form2)];
    xferOrbitText4 = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(incX)), form), ' deg'];
    xferOrbitText5 = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(raanX)), form), ' deg'];
    xferOrbitText6 = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(argX)), form), ' deg'];
    xferOrbitText7 = [paddStr([cap1stLetter(departBody), ' Depart True Anomaly = '],paddLen), num2str(rad2deg(AngleZero2Pi(anomDX)), form), ' deg'];
    xferOrbitText8 = [paddStr([cap1stLetter(arrivalBody), ' Arrive True Anomaly = '],paddLen), num2str(rad2deg(AngleZero2Pi(anomAX)), form), ' deg'];
    
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(departUT);
    dateStrD = formDateStr(year, day, hour, minute, sec);
    xferOrbitText20 = '---------------------';
    xferOrbitText21 = [paddStr('Departure Date = ',0), dateStrD];
    xferOrbitText22 = [paddStr('',22), '(',num2str(departUT, form),' sec UT)'];

    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(arrivalUT);
    dateStrA = formDateStr(year, day, hour, minute, sec);
    xferOrbitText31 = [paddStr('Arrival Date = ',0), dateStrA];
    xferOrbitText32 = [paddStr('',22), '(',num2str(arrivalUT, form),' sec UT)'];
    xferOrbitText33 = [paddStr('Duration = ',20), getDurationStr(arrivalUT-departUT)];
    
    xferOrbitTextstr = {xferOrbitText1, xferOrbitText11, xferOrbitText2, xferOrbitText3, xferOrbitText4, xferOrbitText5, xferOrbitText6, xferOrbitText7, xferOrbitText8, ...
                        xferOrbitText20, xferOrbitText21, xferOrbitText22, ...
                        xferOrbitText31, xferOrbitText32, xferOrbitText33};
    set(mainOrbitText,'String',xferOrbitTextstr);
    set(transOrbitLabel, 'String', [cap1stLetter(cBody),'-Centric Transfer Orbit']);
    
    paddLen = 29;
    form = '%9.5f';
    burnInfoTextstr{1} = ['Burn Information to Depart ', cap1stLetter(departBody)];
    iniOrbit = [eSMA, eEcc, eInc, eRAAN, eArg];
    printDVManeuverInfoToTextbox(burnInfoText, burnInfoTextstr, dVVectNTW, eTA, iniOrbit, gmuDepartBody, form, paddLen);
       
    dv1ManTextUserData = get(burnInfoText,'UserData');
    dv1ManTextUserData(1) = 0;
    dv1ManTextUserData(2) = departUT;
    set(burnInfoText,'UserData',dv1ManTextUserData);
    
    secFromPeri = getTimePastPeriapseFromTA(eTA, eSMA, eEcc, gmuDepartBody);
    
    reportResults = struct();
    reportResults.burnVect = dVVectNTW;
    reportResults.burnTA = eTA;
    if(eEcc<1.0)
        period = computePeriod(eSMA, gmuDepartBody);
        timeBeforePeri = period-secFromPeri;
        reportResults.burnTimePastPeri = secFromPeri;
        reportResults.burnTimeBeforePeri = timeBeforePeri;
        reportResults.iniOrbitPeriod = period;
    else
        if(eTA < 0)
            period = computePeriod(eSMA, gmuDepartBody);
            timeBeforePeri = period-secFromPeri;
            reportResults.burnTimeBeforePeri = timeBeforePeri;
        else
            reportResults.burnTimePastPeri = secFromPeri;
        end
    end
    reportResults.xferOrbit = [smaX eccX incX raanX argX anomDX anomAX];
    reportResults.xferOrbitGMU = gmuXfr;
    reportResults.xferOrbitCBName = cBody;
    reportResults.xferOrbitDepartDate = dateStrD;
    reportResults.xferOrbitArriveDate = dateStrA;
    reportResults.departBodyName = departBody;
    reportResults.arrivalBodyName = arrivalBody;
       
    axisUserData = {};
    axisUserData{1,1} = dVVect;
    axisUserData{1,2} = eRVect;
    axisUserData{1,3} = celBodyData;
    axisUserData{1,4} = eSMA;
    axisUserData{1,5} = eEcc;
    axisUserData{1,6} = eInc;
    axisUserData{1,7} = eRAAN;
    axisUserData{1,8} = eArg;
    axisUserData{1,9} = gmuDepartBody;
    axisUserData{1,10} = hSMA;
    axisUserData{1,11} = hEcc;
    axisUserData{1,12} = hInc;
    axisUserData{1,13} = hRAAN;
    axisUserData{1,14} = hArg;
    axisUserData{1,15} = departBody;
    axisUserData{1,16} = plotBnds;
    
    axisUserData{2,1} = arrivalBody;
    axisUserData{2,2} = departUT;
    axisUserData{2,3} = arrivalUT;
    axisUserData{2,4} = gmuXfr;
    axisUserData{2,5} = smaX;
    axisUserData{2,6} = eccX;
    axisUserData{2,7} = incX;
    axisUserData{2,8} = raanX;
    axisUserData{2,9} = argX;
    axisUserData{2,10} = anomAX;
    axisUserData{2,11} = anomDX;
    
    reportResults.axisUserData = axisUserData;
    set(departDispGUI,'UserData',{reportResults});
    
    reset(departAxis);       
    set(departAxis,'UserData',axisUserData);
    hPlotBtnGrp = findobj(departDispGUI,'Tag','plotDisplayPanel');
    hTypeBtn = findobj(hPlotBtnGrp,'Tag','departureOrbitRadio');
    set(hTypeBtn,'Value', 1);
    hLegend = findobj(departDispGUI,'Type','axes','Tag','legend');
    delete(hLegend);
    plotBodyDepartOrbit(departAxis);
end
