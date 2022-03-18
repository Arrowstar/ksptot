function copyOrbitToClipboardFromText(hEpoch, hSMA, hEcc, hInc, hRAAN, hArg, hAnomaly, isTrueAnomaly, bodyID)
%copyOrbitToClipboardFromText Summary of this function goes here
%   Detailed explanation goes here
    global GLOBAL_OrbitClipboard;

    if(~isempty(hEpoch))
        GLOBAL_OrbitClipboard(1) = str2double(get(hEpoch, 'String'));
    else
        GLOBAL_OrbitClipboard(1) = 0;
    end
    
    GLOBAL_OrbitClipboard(2) = str2double(get(hSMA, 'String'));
    GLOBAL_OrbitClipboard(3) = str2double(get(hEcc, 'String'));
    GLOBAL_OrbitClipboard(4) = deg2rad(str2double(get(hInc, 'String')));
    GLOBAL_OrbitClipboard(5) = deg2rad(str2double(get(hRAAN, 'String')));
    GLOBAL_OrbitClipboard(6) = deg2rad(str2double(get(hArg, 'String')));
    
    if(~isempty(hAnomaly))
        anomaly = deg2rad(str2double(get(hAnomaly, 'String')));
        if(isTrueAnomaly == true)
            tru = anomaly;
        else
            mean = anomaly;
            ecc = str2double(get(hEcc, 'String'));
            tru = computeTrueAnomFromMean(mean, ecc);
        end
        GLOBAL_OrbitClipboard(7) = tru;
    else
        GLOBAL_OrbitClipboard(7) = 0;
    end
    
    GLOBAL_OrbitClipboard(8) = bodyID;
end