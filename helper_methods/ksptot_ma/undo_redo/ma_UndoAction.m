function ma_UndoAction(handles)
%ma_UndoAction Summary of this function goes here
%   Detailed explanation goes here
    undo_states = getappdata(handles.ma_MainGUI,'undo_states');
    undo_pointer = getappdata(handles.ma_MainGUI,'undo_pointer');
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    if(undo_pointer < 1 || undo_pointer > size(undo_states,1))
        return;
    end
    
    if(undo_pointer == size(undo_states,1))
        undo_states{end+1,1} = maData;
        undo_states{end,2}   = '';
    end
    
    maData = undo_states{undo_pointer,1};
    undo_pointer = undo_pointer - 1;
    maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,findobj('Tag','scriptWorkingLbl'));
    maData.celBodyData = celBodyData;
    setappdata(handles.ma_MainGUI,'undo_pointer',undo_pointer);
    setappdata(handles.ma_MainGUI,'undo_states',undo_states);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    ma_processData(handles);
end