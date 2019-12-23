function pasteOrbitFromClipboard(hEpoch, hSMA, hEcc, hInc, hRAAN, hArg, hAnomaly, isTrueAnomaly, hCelBody, celBodyData)
%pasteOrbitFromClipboard Summary of this function goes here
%   Detailed explanation goes here
    global GLOBAL_OrbitClipboard;
    
    if(length(GLOBAL_OrbitClipboard) == 8)
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
        
        %TODO paste the planet body ID
        bodyID = GLOBAL_OrbitClipboard(8);
        if(~isempty(hCelBody) && ~isempty(celBodyData))
            bodyStrs = get(hCelBody,'String');
            if(~iscell(bodyStrs))
                bodyStrsTmp = bodyStrs;
                
                bodyStrs = {};
                for(i=1:size(bodyStrsTmp,1)) %#ok<NO4LP>
                    bodyStrs{i} = bodyStrsTmp(i,:); %#ok<AGROW>
                end
            end
            
            bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
            ind = find(ismember(strtrim(bodyStrs), bodyInfo.name));
            if(~isempty(ind))
                hCelBody.Value = ind;
            end
        end
    else
        GLOBAL_OrbitClipboard = [];
        warndlg('Could not paste orbit.  Orbit clipboard contents are either empty or invalid.  Try copying an orbit to the clipboard first.','Could not paste orbit.');
    end
end

