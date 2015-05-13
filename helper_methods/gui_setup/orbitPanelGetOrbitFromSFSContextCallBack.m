function refBody = orbitPanelGetOrbitFromSFSContextCallBack(mainGUIHandle, hSMA, hECC, hINC, hRAAN, hARG, varargin)
%orbitPanelGetOrbitFromSFSContextCallBack Summary of this function goes here
%   Detailed explanation goes here
    mainUserData = get(mainGUIHandle,'UserData');
    prevPathName = mainUserData{3,1};
    
    refBody = [];
    [orbit,PathName] = importOrbitGUI(1, prevPathName);
    if(not(isempty(orbit)))
        set(hSMA, 'String', fullAccNum2Str(orbit{3}));
        set(hECC, 'String', fullAccNum2Str(orbit{4}));
        set(hINC, 'String', fullAccNum2Str(orbit{5}));
        set(hRAAN, 'String', fullAccNum2Str(orbit{6}));
        set(hARG, 'String', fullAccNum2Str(orbit{7}));
        refBody = orbit{10};
        
        if(nargin == 8)
            hMA = varargin{1};
            hEpoch = varargin{2};
            set(hMA, 'String', fullAccNum2Str(orbit{8}));
            set(hEpoch, 'String', fullAccNum2Str(orbit{9}));
        end
        
        mainUserData{3,1} = PathName;
    end
    
    set(mainGUIHandle,'UserData',mainUserData);
end

