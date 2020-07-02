function burn1InfoText = printDVManeuverInfoToTextbox(hDvManInfoText, burnInfoTextHeader, deltaVNTW, burnTAOrbit, iniOrbit, gmuXfr, form, paddLen, varargin)
%printDVManeuverInfoToTextbox Summary of this function goes here
%   Detailed explanation goes here
       
        if(isempty(varargin))
            ut = [];
        else
            ut = varargin{1};
        end

        hRule = getHRule();
        
        burn1InfoText = burnInfoTextHeader;
        burn1InfoText{end+1} = hRule;
        burn1InfoText{end+1} = [paddStr('Total Delta-V = ',paddLen), num2str(norm(deltaVNTW), form), ' km/s'];
        burn1InfoText{end+1} = [paddStr('Prograde Delta-V = ',paddLen), num2str(1000*deltaVNTW(1), form), ' m/s'];
        burn1InfoText{end+1} = [paddStr('Orbit Normal Delta-V = ',paddLen), num2str(1000*deltaVNTW(2), form), ' m/s'];
        burn1InfoText{end+1} = [paddStr('Radial Delta-V = ',paddLen), num2str(1000*deltaVNTW(3), form), ' m/s'];
        burn1InfoText{end+1} = '---------------------';
        burn1InfoText{end+1} = [paddStr('Burn True Anomaly = ',paddLen), num2str(rad2deg(burnTAOrbit), form), ' deg'];
        secFromPeri = getTimePastPeriapseFromTA(burnTAOrbit, iniOrbit(1), iniOrbit(2), gmuXfr);
        if(iniOrbit(2)<1.0)
            period = computePeriod(iniOrbit(1), gmuXfr);
            burn1InfoText{end+1} = [paddStr('Burn Time Past Peri. = ',paddLen), num2str(secFromPeri, form), ' sec'];
            burn1InfoText{end+1} = [paddStr('Burn Time Before Peri. = ',paddLen), num2str(period-secFromPeri, form), ' sec'];
            burn1InfoText{end+1} = [paddStr('Initial Orbit Period = ',paddLen), num2str(period, form), ' sec'];
        else
            if(burnTAOrbit < 0)
                burn1InfoText{end+1} = [paddStr('Burn Time Before Peri. = ',paddLen), num2str(secFromPeri, form), ' sec'];
            else
                burn1InfoText{end+1} = [paddStr('Burn Time Past Peri. = ',paddLen), num2str(secFromPeri, form), ' sec'];
            end
        end
        if(~isempty(ut))
            burn1InfoText{end+1} = [paddStr('Burn UT = ',paddLen), num2str(ut,form), ' sec'];
        end
        set(hDvManInfoText, 'String', burn1InfoText);
        
        %first number is type of time in the second element: 0 is UT, 1 is
        %time past periapse;
        %Note: Code after this method is called may modify UserData
        %(specifically to change the type to strict UT time)
        if(~isempty(ut))
            set(hDvManInfoText, 'UserData', [0, ut, 1000*deltaVNTW(1), 1000*deltaVNTW(2), 1000*deltaVNTW(3)]);
        else
            set(hDvManInfoText, 'UserData', [1, secFromPeri, 1000*deltaVNTW(1), 1000*deltaVNTW(2), 1000*deltaVNTW(3)]);
        end
end