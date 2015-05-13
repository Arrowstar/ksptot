function pasteOrbitFromClipboard(hEpoch, hSMA, hEcc, hInc, hRAAN, hArg, hAnomaly, isTrueAnomaly)
%pasteOrbitFromClipboard Summary of this function goes here
%   Detailed explanation goes here
    global GLOBAL_OrbitClipboard;
    
    if(length(GLOBAL_OrbitClipboard) == 7)
        if(~isempty(hEpoch))
            set(hEpoch, 'String', fullAccNum2Str(GLOBAL_OrbitClipboard(1)));
        end
        set(hSMA, 'String', fullAccNum2Str(GLOBAL_OrbitClipboard(2)));
        set(hEcc, 'String', fullAccNum2Str(GLOBAL_OrbitClipboard(3)));
        set(hInc, 'String', fullAccNum2Str(rad2deg(GLOBAL_OrbitClipboard(4))));
        set(hRAAN, 'String', fullAccNum2Str(rad2deg(GLOBAL_OrbitClipboard(5))));
        set(hArg, 'String', fullAccNum2Str(rad2deg(GLOBAL_OrbitClipboard(6))));

        if(~isempty(hAnomaly))
            if(isTrueAnomaly == true)
                set(hAnomaly, 'String', fullAccNum2Str(rad2deg(GLOBAL_OrbitClipboard(7))));
            else
                mean = rad2deg(computeMeanFromTrueAnom(GLOBAL_OrbitClipboard(7), GLOBAL_OrbitClipboard(3)));
                set(hAnomaly, 'String', fullAccNum2Str(mean));
            end
        end
    else
        GLOBAL_OrbitClipboard = [];
        warndlg('Could not paste orbit.  Orbit clipboard contents are either empty or invalid.  Try copying an orbit to the clipboard first.','Could not paste orbit.');
    end
end

