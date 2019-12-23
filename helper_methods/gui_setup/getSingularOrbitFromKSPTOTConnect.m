function [orbitRow] = getSingularOrbitFromKSPTOTConnect(guid)
    orbitRow = {};

    if(~isempty(guid))
        name = readStringFromKSPTOTConnect('GetVesselNameByGUID', guid, true);
        status = readStringFromKSPTOTConnect('GetVesselStatusByGUID', guid, true);
        orbitDbl = readDoublesFromKSPTOTConnect('GetVesselOrbitByGUID', guid, true);
    else
        name = readStringFromKSPTOTConnect('GetActiveVesselName', '', true);
        status = '';
        orbitDbl = readDoublesFromKSPTOTConnect('GetActiveVesselOrbit', '', true);
    end

    orbitRow{1} = name;
    orbitRow{2} = status;
    orbitRow{3} = orbitDbl(1);
    orbitRow{4} = orbitDbl(2);
    orbitRow{5} = orbitDbl(3);
    orbitRow{6} = orbitDbl(4);
    orbitRow{7} = orbitDbl(5);    
    
    if(orbitDbl(2) > 1.0)
        orbitRow{8} = orbitDbl(8);
    else
        orbitRow{8} = AngleZero2Pi(orbitDbl(8));
    end
    
    orbitRow{9} = orbitDbl(9);
    orbitRow{10} = orbitDbl(13);

    if(orbitRow{6} < 0)
        orbitRow{6} = orbitRow{6} + 360;
    end

    if(orbitRow{7} < 0)
        orbitRow{7} = orbitRow{7} + 360;
    end
end

