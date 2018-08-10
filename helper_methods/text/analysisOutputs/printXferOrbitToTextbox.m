function printXferOrbitToTextbox(hXfrOrbitText, xferOrbitTextHeader, xfrOrbit, form, paddLen)
%printXferOrbitToTextbox Summary of this function goes here
%   Detailed explanation goes here

    hRule = getHRule();

    xferOrbitText = xferOrbitTextHeader;
    xferOrbitText{end+1} = hRule;
    xferOrbitText{end+1} = [paddStr('Semi-major Axis = ',paddLen), num2str(xfrOrbit(1), form), ' km'];
    xferOrbitText{end+1} = [paddStr('Eccentricity = ', paddLen), num2str(xfrOrbit(2))];
    xferOrbitText{end+1} = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(xfrOrbit(3))), form), ' deg'];
    xferOrbitText{end+1} = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(xfrOrbit(4))), form), ' deg'];
    xferOrbitText{end+1} = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(xfrOrbit(5))), form), ' deg'];
    xferOrbitText{end+1} = '---------------------';
    xferOrbitText{end+1} = [paddStr('Departure True Anomaly = ',paddLen), num2str(rad2deg(AngleZero2Pi(xfrOrbit(6))), form), ' deg'];
    xferOrbitText{end+1} = [paddStr('Arrival True Anomaly = ',paddLen), num2str(rad2deg(AngleZero2Pi(xfrOrbit(7))), form), ' deg'];
    set(hXfrOrbitText,'String',xferOrbitText);   
end

