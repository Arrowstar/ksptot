function ma_UndoRedoAddState(handles, actionName)
%ma_UndoRedoAddState Summary of this function goes here
%   Detailed explanation goes here

    undo_states = getappdata(handles.ma_MainGUI,'undo_states');
    undo_pointer = getappdata(handles.ma_MainGUI,'undo_pointer');
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    if(undo_pointer > size(undo_states,1))
        error('Undo/redo states and the pointer are out of sync.');
    end

    %remove data we don't want stored in the undo/redo state because either
    %it gets recomputed or is not necessary
    maData.stateLog = [];
    maData.celBodyData = [];
    maData.optimizer.problem = []; 
%     for(i=1:size(maData.script,2)) %#ok<*NO4LP>
%         if(isfield(maData.script{i},'centralBody'))
%             maData.script{i}.centralBody.atmopresscurve = [];
%             maData.script{i}.centralBody.atmotempcurve = [];
%             maData.script{i}.centralBody.atmotempsunmultcurve = [];
%             maData.script{i}.centralBody.lattempbiascurve = [];
%             maData.script{i}.centralBody.lattempsunmultcurve = [];
%         end
%     end
    
    if(undo_pointer == 0)
        undo_states = {};
        undo_states{end+1,1} = maData;
        undo_states{end,2}   = actionName;
        undo_pointer = 1;
    else
        undo_states = undo_states(1:undo_pointer,:);
        undo_states{end+1,1} = maData;
        undo_states{end,2}   = actionName;
        undo_pointer = undo_pointer + 1;
    end
    
    maxUndos = 25;
    if(undo_pointer>maxUndos)
        undo_states = undo_states(end-(maxUndos-1):end,:);
        undo_pointer = maxUndos;
    end
    
    setappdata(handles.ma_MainGUI,'undo_states',undo_states);
    setappdata(handles.ma_MainGUI,'undo_pointer',undo_pointer);
    
    curName = get(handles.ma_MainGUI,'Name');
    if(~strcmpi(curName(end),'*'))
        set(handles.ma_MainGUI,'Name',[curName,'*']);
    end
end

