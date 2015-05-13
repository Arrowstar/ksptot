function hyperOrbitText = printHyperOrbitsFMSToTextbox(hHyperbolicOrbitsText, departBody, flybyBody, hDepartOrbit, flyByOrbitIn, flyByOrbitOut, flyByRp, form, paddLen)
%printHyperOrbitsFMSToTextbox Summary of this function goes here
%   Detailed explanation goes here
        hRule = getHRule();

        hyperOrbitText{1} = ['Hyperbolic Departure Orbit from ', cap1stLetter(departBody)];
        hyperOrbitText{2} = hRule;
        hyperOrbitText{3} = [paddStr('Semi-major Axis = ',paddLen), num2str(hDepartOrbit(1), form), ' km'];
        hyperOrbitText{4} = [paddStr('Eccentricity = ', paddLen), num2str(hDepartOrbit(2))];
        hyperOrbitText{5} = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(hDepartOrbit(3))), form), ' deg'];
        hyperOrbitText{6} = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(hDepartOrbit(4))), form), ' deg'];
        hyperOrbitText{7} = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(hDepartOrbit(5))), form), ' deg'];
        hyperOrbitText{8} = hRule;
        hyperOrbitText{9} = ['Inbound Hyperbolic Flyby Orbit to ', cap1stLetter(flybyBody)];
        hyperOrbitText{10} = hRule;
        hyperOrbitText{11} = [paddStr('Semi-major Axis = ',paddLen), num2str(flyByOrbitIn(1), form), ' km'];
        hyperOrbitText{12} = [paddStr('Eccentricity = ', paddLen), num2str(flyByOrbitIn(2))];
        hyperOrbitText{13} = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(flyByOrbitIn(3))), form), ' deg'];
        hyperOrbitText{14} = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(flyByOrbitIn(4))), form), ' deg'];
        hyperOrbitText{15} = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(flyByOrbitIn(5))), form), ' deg'];
        hyperOrbitText{16} = [paddStr('Periapse Radius = ',paddLen), num2str(flyByRp, form), ' km'];
        hyperOrbitText{17} = hRule;
        hyperOrbitText{18} = ['Outbound Hyperbolic Flyby Orbit from ', cap1stLetter(flybyBody)];
        hyperOrbitText{19} = hRule;
        hyperOrbitText{20} = [paddStr('Semi-major Axis = ',paddLen), num2str(flyByOrbitOut(1), form), ' km'];
        hyperOrbitText{21} = [paddStr('Eccentricity = ', paddLen), num2str(flyByOrbitOut(2))];
        hyperOrbitText{22} = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(flyByOrbitOut(3))), form), ' deg'];
        hyperOrbitText{23} = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(flyByOrbitOut(4))), form), ' deg'];
        hyperOrbitText{24} = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(flyByOrbitOut(5))), form), ' deg'];
        hyperOrbitText{25} = [paddStr('Periapse Radius = ',paddLen), num2str(flyByRp, form), ' km'];
        set(hHyperbolicOrbitsText,'String',hyperOrbitText);
end

