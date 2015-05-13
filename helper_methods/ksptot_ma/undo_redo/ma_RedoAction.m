function ma_RedoAction(handles)
%ma_RedoAction Summary of this function goes here
%   Detailed explanation goes here
    undo_states = getappdata(handles.ma_MainGUI,'undo_states');
    undo_pointer = getappdata(handles.ma_MainGUI,'undo_pointer');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    if(undo_pointer + 1 < 1 || undo_pointer + 2 > size(undo_states,1))
        return;
    end
    
    maData = undo_states{undo_pointer+2,1};
    undo_pointer = undo_pointer + 1;
    maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,findobj('Tag','scriptWorkingLbl'));
    setappdata(handles.ma_MainGUI,'undo_pointer',undo_pointer);
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    ma_processData(handles);
end

