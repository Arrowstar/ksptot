function [cumData] = getStageData(lvDef)
    stageBurnTimes = [];
    cumData = [];
    for(i=1:size(lvDef,1)) %#ok<*NO4LP>
        thrust = lvDef{i,4};
        Isp = lvDef{i,5};
        g0Isp = getG0Ms();
        mdot = -(thrust) / (g0Isp * Isp); %kN / (m/s/s * s) = (ton*m/s/s) / (m/s) = ton/s
        fuMass = lvDef{i,3};
        stageBurnTimes(i) = fuMass/(-mdot); %#ok<AGROW>
        massStart = sum([lvDef{i:end,2}]) + sum([lvDef{i:end,3}]);
        massEnd = massStart - fuMass;
        dryMassCum = sum([lvDef{i:end,2}]);
        fuMassCum = sum([lvDef{i:end,3}]);
        coastDur = lvDef{i,6};
        cDa = lvDef{i,7};
        cumData(i,:) = [stageBurnTimes(i), thrust, mdot, massStart, massEnd, dryMassCum, fuMassCum, coastDur, cDa]; %#ok<AGROW>
    end