function populateBodiesCombo(handles, hBodiesCombo, varargin)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
%     bodies = fields(celBodyData);
%     
%     bodiesStr = cell(length(bodies),1);
%     for(i = 1:length(bodies)) %#ok<*NO4LP>
%         body = bodies{i};
%         bodiesStr{i} = celBodyData.(body).name;
%     end

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
    elseif(length(bodiesStr) >= 1)
        set(hBodiesCombo, 'value', 1);
    end
end