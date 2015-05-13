function burnInfoText = printDVManeuversFMSToTextbox(hDvManInfoText, departBody, flybyBody, dVDepartVectNTW, ePreDepartOrbit, eTA, departBodyInfo, flyByDVVectNTW,  form, paddLen)
%printDVManeuversFMSToTextbox Summary of this function goes here
%   Detailed explanation goes here
        hRule = getHRule();
        
        ePeriod = computePeriod(ePreDepartOrbit(1), departBodyInfo.gm);

        burnInfoText{1} = ['Burn Information to Depart ', cap1stLetter(departBody)];
        burnInfoText{end+1} = hRule;
        burnInfoText{end+1} = [paddStr('Total Delta-V = ',paddLen), num2str(norm(dVDepartVectNTW), form), ' km/s'];
        burnInfoText{end+1} = [paddStr('Prograde Delta-V = ',paddLen), num2str(1000*dVDepartVectNTW(1), form), ' m/s'];
        burnInfoText{end+1} = [paddStr('Orbit Normal Delta-V = ',paddLen), num2str(1000*dVDepartVectNTW(2), form), ' m/s'];
        burnInfoText{end+1} = [paddStr('Radial Delta-V = ',paddLen), num2str(1000*dVDepartVectNTW(3), form), ' m/s'];
        burnInfoText{end+1} = '---------------------';
        burnInfoText{end+1} = [paddStr('Departure True Anomaly = ',paddLen), num2str(rad2deg(eTA), form), ' deg'];
        MA = AngleZero2Pi(computeMeanFromTrueAnom(eTA, ePreDepartOrbit(2)));
        eN = computeMeanMotion(ePreDepartOrbit(1), departBodyInfo.gm);
        secFromPeri = MA/eN;
        burnInfoText{end+1} = [paddStr('Departure Time Past Peri. = ',paddLen), num2str(secFromPeri, form), ' sec'];
        burnInfoText{end+1} = [paddStr('Departure Time Before Peri. = ',paddLen), num2str(ePeriod-secFromPeri, form), ' sec'];
        burnInfoText{end+1} = hRule;
        burnInfoText{end+1} = ['Burn Information to Depart ', cap1stLetter(flybyBody)];
        burnInfoText{end+1} = hRule;
        burnInfoText{end+1} = [paddStr('Total Delta-V = ',paddLen), num2str(norm(flyByDVVectNTW), form), ' km/s'];
        burnInfoText{end+1} = [paddStr('Prograde Delta-V = ',paddLen), num2str(1000*flyByDVVectNTW(1), form), ' m/s'];
        burnInfoText{end+1} = [paddStr('Orbit Normal Delta-V = ',paddLen), num2str(1000*flyByDVVectNTW(2), form), ' m/s'];
        burnInfoText{end+1} = [paddStr('Radial Delta-V = ',paddLen), num2str(1000*flyByDVVectNTW(3), form), ' m/s'];
        %flyby burn occurs at periapse per the algorithm - this is hardcoded below (next two lines)
        burnInfoText{end+1} = '---------------------';
        burnInfoText{end+1} = [paddStr('Departure True Anomaly = ',paddLen), num2str(rad2deg(0.0), form), ' deg'];
        burnInfoText{end+1} = [paddStr('Departure Time Past Peri. = ',paddLen), num2str(0.0, form), ' sec'];
        burnInfoText{end+1} = [paddStr('Departure Time Before Peri. = ',paddLen), num2str(0.0, form), ' sec'];
        set(hDvManInfoText,'String',burnInfoText);

        %first number is type of time in the second element: 0 is UT, 1 is
        %time past periapse;
        %Note: Code after this method is called may modify UserData
        %(specifically to change the type to strict UT time)
        set(hDvManInfoText, 'UserData', [1, secFromPeri, 1000*dVDepartVectNTW(1), 1000*dVDepartVectNTW(2), 1000*dVDepartVectNTW(3)]);
end

