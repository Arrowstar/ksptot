function xferOrbitText = printXfrOrbitsFMSToTextbox(hTransferOrbitsText, departBody, flybyBody, arriveBody, xferOrbitIn, xferOrbitOut, departUT, flybyUT, arriveUT, gmuXfr, form, paddLen)
%printXfrOrbitsFMSToTextbox Summary of this function goes here
%   Detailed explanation goes here
        
        hRule = getHRule();
        
        xferOrbitText = {};
        xferOrbitText{end+1} = ['Phase 1 Transfer Orbit (', cap1stLetter(departBody), ' -> ', cap1stLetter(flybyBody), ')'];
        xferOrbitText{end+1} = hRule;
        xferOrbitText{end+1} = [paddStr('Semi-major Axis = ',paddLen), num2str(xferOrbitIn(1), form), ' km'];
        xferOrbitText{end+1} = [paddStr('Eccentricity = ', paddLen), num2str(xferOrbitIn(2))];
        xferOrbitText{end+1} = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbitIn(3))), form), ' deg'];
        xferOrbitText{end+1} = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbitIn(4))), form), ' deg'];
        xferOrbitText{end+1} = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbitIn(5))), form), ' deg'];
        xferOrbitText{end+1} = [paddStr('Period = ',paddLen), num2str(computePeriod(xferOrbitIn(1), gmuXfr), form), ' sec'];
        xferOrbitText{end+1} = [paddStr([cap1stLetter(departBody), ' Depart True Anomaly = '],paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbitIn(6))), form), ' deg'];
        xferOrbitText{end+1} = [paddStr([cap1stLetter(flybyBody), ' Arrive True Anomaly = '],paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbitIn(7))), form), ' deg'];
        xferOrbitText{end+1} = hRule;
        xferOrbitText{end+1} = ['Phase 2 Transfer Orbit (', cap1stLetter(flybyBody), ' -> ', cap1stLetter(arriveBody), ')'];
        xferOrbitText{end+1} = hRule;
        xferOrbitText{end+1} = [paddStr('Semi-major Axis = ',paddLen), num2str(xferOrbitOut(1), form), ' km'];
        xferOrbitText{end+1} = [paddStr('Eccentricity = ', paddLen), num2str(xferOrbitOut(2))];
        xferOrbitText{end+1} = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbitOut(3))), form), ' deg'];
        xferOrbitText{end+1} = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbitOut(4))), form), ' deg'];
        xferOrbitText{end+1} = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbitOut(5))), form), ' deg'];
        xferOrbitText{end+1} = [paddStr('Period = ',paddLen), num2str(computePeriod(xferOrbitOut(1), gmuXfr), form), ' sec'];
        xferOrbitText{end+1} = [paddStr([cap1stLetter(flybyBody), ' Depart True Anomaly = '],paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbitOut(6))), form), ' deg'];
        xferOrbitText{end+1} = [paddStr([cap1stLetter(arriveBody), ' Arrive True Anomaly = '],paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbitOut(7))), form), ' deg'];
        xferOrbitText{end+1} = hRule;
        
        xferOrbitTextDates = printManeuverDatesFMS(departUT, flybyUT, arriveUT, form, paddLen);
        xferOrbitText = horzcat(xferOrbitText,xferOrbitTextDates);
        
        set(hTransferOrbitsText,'String',xferOrbitText);

end

