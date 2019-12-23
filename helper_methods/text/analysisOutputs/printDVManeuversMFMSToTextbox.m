function [str] = printDVManeuversMFMSToTextbox(hDvManInfoText,waypoints,dVDepartVectNTW,deltaVVectNTW,eOrbit,orbitsIn,paddLen,form)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

    hRule = getHRule();
    str = {};
    
    sumDv = 0;
    for(i=1:length(waypoints)-1) %#ok<*NO4LP>
        if(i==1)
            dvVect = dVDepartVectNTW;
            ta = eOrbit(8);
        else
            dvVect = deltaVVectNTW(:,i-1);
            ta = orbitsIn(i-1,6);
        end
        
        str{end+1} = ['Burn Information to Depart ', cap1stLetter(waypoints{i}.name)];
        str{end+1} = hRule;
        str{end+1} = [paddStr('Total Delta-V = ',paddLen), num2str(norm(dvVect), form), ' km/s'];
        str{end+1} = [paddStr('Prograde Delta-V = ',paddLen), num2str(1000*dvVect(1), form), ' m/s'];
        str{end+1} = [paddStr('Orbit Normal Delta-V = ',paddLen), num2str(1000*dvVect(2), form), ' m/s'];
        str{end+1} = [paddStr('Radial Delta-V = ',paddLen), num2str(1000*dvVect(3), form), ' m/s'];
        str{end+1} = '---------------------';
        str{end+1} = [paddStr('Burn True Anomaly = ',paddLen), num2str(rad2deg(ta), form), ' deg'];
        str{end+1} = hRule;
        
        sumDv = sumDv + norm(dvVect);
    end
    
    str{end+1} = [paddStr('Total Mission Delta-V = ',paddLen), num2str(sumDv, form), ' km/s'];
    
    set(hDvManInfoText,'String',str);
end

