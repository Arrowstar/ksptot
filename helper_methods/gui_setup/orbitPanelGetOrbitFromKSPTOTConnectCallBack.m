function  refBody = orbitPanelGetOrbitFromKSPTOTConnectCallBack(hSMA, hECC, hINC, hRAAN, hARG, varargin)
%orbitPanelGetOrbitFromKSPConnectCallBack Summary of this function goes here
%   Detailed explanation goes here

    refBody = [];
    [orbit,~] = importOrbitGUI(-1, 'KSPTOTConnect');
    if(not(isempty(orbit)))
        set(hSMA, 'String', fullAccNum2Str(orbit{3}));
        set(hECC, 'String', fullAccNum2Str(orbit{4}));
        set(hINC, 'String', fullAccNum2Str(orbit{5}));
        set(hRAAN, 'String', fullAccNum2Str(orbit{6}));
        set(hARG, 'String', fullAccNum2Str(orbit{7}));
        refBody = orbit{10};
        
        if(nargin == 7)
            hMA = varargin{1};
            hEpoch = varargin{2};
            set(hMA, 'String', fullAccNum2Str(rad2deg(orbit{8})));
            set(hEpoch, 'String', fullAccNum2Str(orbit{9}));
        end
    end
end

