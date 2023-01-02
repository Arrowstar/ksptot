function populateBodiesCombo(celBodyData, hBodiesCombo, varargin)
    if(length(varargin) >= 1)
        insertBlankLineAtTop = varargin{1};
    else
        insertBlankLineAtTop = false;
    end

    [bodiesStr, ~] = ma_getSortedBodyNames(celBodyData);
    
    if(insertBlankLineAtTop)
        bodiesStr = vertcat({''}, bodiesStr);
    end
    
    set(hBodiesCombo, 'String', bodiesStr);
    if(length(bodiesStr) >= 1)
        set(hBodiesCombo, 'value', 1);
    end
end