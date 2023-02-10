function [str] = printHyperOrbitsMFMSToTextbox(hHyperbolicOrbitsText, waypoints, hOrbitDepart, orbitsIn, orbitsOut, vInfArrive, OUnitVector, vInfMag, form, form2, paddLen)
%printHyperOrbitsMFMSToTextbox Summary of this function goes here
%   Detailed explanation goes here

    hRule = getHRule();
    
    [vInfRA,vInfDec,~] = cart2sph(OUnitVector(1),OUnitVector(2),OUnitVector(3));
    vInfRA = rad2deg(vInfRA);
    vInfDec = rad2deg(vInfDec);
    
    str = {};
    str{end+1} = ['Hyperbolic Departure Orbit from ', cap1stLetter(waypoints{1}.name)];
    str{end+1} = hRule;
    str{end+1} = [paddStr('Semi-major Axis = ',paddLen), num2str(hOrbitDepart(1), form), ' km'];
    str{end+1} = [paddStr('Eccentricity = ', paddLen), num2str(hOrbitDepart(2), form2)];
    str{end+1} = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(hOrbitDepart(3))), form), ' deg'];
    str{end+1} = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(hOrbitDepart(4))), form), ' deg'];
    str{end+1} = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(hOrbitDepart(5))), form), ' deg'];
    str{end+1} = '---------------------';
    str{end+1} = [paddStr('Out. Hyp. Vel. Vect Rt. Asc. = ',paddLen), num2str(vInfRA, form), ' deg'];
    str{end+1} = [paddStr('Out. Hyp. Vel. Vect Declin. = ',paddLen), num2str(vInfDec, form), ' deg'];
    str{end+1} = [paddStr('Out. Hyp. Vel. Magnitude = ',paddLen), num2str(vInfMag, form2), ' km/s'];
    
    for(i=2:length(waypoints)) %#ok<*NO4LP>
        if(i < length(waypoints))
            [~, flyByRp] = computeApogeePerigee(orbitsIn(i-1,1), orbitsIn(i-1,2));
            
            str{end+1} = hRule;
            str{end+1} = ['Inbound Hyperbolic Flyby Orbit to ', cap1stLetter(waypoints{i}.name)];
            str{end+1} = hRule;
            str{end+1} = [paddStr('Semi-major Axis = ',paddLen), num2str(orbitsIn(i-1,1), form), ' km'];
            str{end+1} = [paddStr('Eccentricity = ', paddLen), num2str(orbitsIn(i-1,2), form2)];
            str{end+1} = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(orbitsIn(i-1,3))), form), ' deg'];
            str{end+1} = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(orbitsIn(i-1,4))), form), ' deg'];
            str{end+1} = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(orbitsIn(i-1,5))), form), ' deg'];
            str{end+1} = [paddStr('Periapse Radius = ',paddLen), num2str(flyByRp, form), ' km'];

            hOrbit = orbitsOut(i-1,:);
            [~, OUnitVector, vInfMag] = computeHyperSVectOVect(hOrbit(1), hOrbit(2), hOrbit(3), hOrbit(4), hOrbit(5), 0.0, waypoints{i}.gm);
            OUnitVector = normVector(OUnitVector);
            [vInfRA,vInfDec,~] = cart2sph(OUnitVector(1),OUnitVector(2),OUnitVector(3));
            vInfRA = rad2deg(vInfRA);
            vInfDec = rad2deg(vInfDec);
            
            str{end+1} = hRule;
            str{end+1} = ['Outbound Hyperbolic Flyby Orbit from ', cap1stLetter(waypoints{i}.name)];
            str{end+1} = hRule;
            str{end+1} = [paddStr('Semi-major Axis = ',paddLen), num2str(orbitsOut(i-1,1), form), ' km'];
            str{end+1} = [paddStr('Eccentricity = ', paddLen), num2str(orbitsOut(i-1,2))];
            str{end+1} = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(orbitsOut(i-1,3))), form), ' deg'];
            str{end+1} = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(orbitsOut(i-1,4))), form), ' deg'];
            str{end+1} = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(orbitsOut(i-1,5))), form), ' deg'];
            str{end+1} = [paddStr('Periapse Radius = ',paddLen), num2str(flyByRp, form), ' km'];
            str{end+1} = '---------------------';
            str{end+1} = [paddStr('Out. Hyp. Vel. Vect Rt. Asc. = ',paddLen), num2str(vInfRA, form), ' deg'];
            str{end+1} = [paddStr('Out. Hyp. Vel. Vect Declin. = ',paddLen), num2str(vInfDec, form), ' deg'];
            str{end+1} = [paddStr('Out. Hyp. Vel. Magnitude = ',paddLen), num2str(vInfMag, form2), ' km/s'];
        else
            [vInfRA,vInfDec,~] = cart2sph(vInfArrive(1),vInfArrive(2),vInfArrive(3));
            vInfRA = rad2deg(vInfRA);
            vInfDec = rad2deg(vInfDec);
            
            str{end+1} = hRule;
            str{end+1} = ['Inbound Hyperbolic Orbit to ', cap1stLetter(waypoints{i}.name)];
            str{end+1} = hRule;
            str{end+1} = [paddStr('Inb. Hyp. Vel. Vect Rt. Asc. = ',paddLen), num2str(vInfRA, form), ' deg'];
            str{end+1} = [paddStr('Inb. Hyp. Vel. Vect Declin. = ',paddLen), num2str(vInfDec, form), ' deg'];
            str{end+1} = [paddStr('Inb. Hyp. Vel. Magnitude = ',paddLen), num2str(norm(vInfArrive), form), ' km/s'];
%             str{end+1} = [paddStr('Hyperbolic Excess Vel. = ',paddLen), num2str(norm(vInfArrive), form), ' km/s'];
        end
    end
    
    set(hHyperbolicOrbitsText,'String',str);
end

