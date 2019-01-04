classdef LVD_UndoRedoStateSet < matlab.mixin.SetGet
    %LVD_UndoRedoStateSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        undo_states(:,1) LVD_UndoRedoState
        undo_pointer (1,1) double = 0
    end
    
    methods
        function obj = LVD_UndoRedoStateSet()
            obj.undo_states = LVD_UndoRedoState.empty(1,0);
        end
        
        function obj = addState(obj, hLvdFig, lvdData, actionName)
            if(obj.undo_pointer > length(obj.undo_states))
                error('Undo/redo states and the pointer are out of sync.');
            end

            if(obj.undo_pointer == 0)
                obj.undo_states = LVD_UndoRedoState.empty(1,0);
                obj.undo_states(end+1) = LVD_UndoRedoState(lvdData, actionName);
                obj.undo_pointer = 1;
            else
                t_undo_states = obj.undo_states(1:obj.undo_pointer,:);
                t_undo_states(end+1) = LVD_UndoRedoState(lvdData, actionName);
                obj.undo_states = t_undo_states;
                obj.undo_pointer = obj.undo_pointer + 1;
            end
            
            maxUndos = 25;
            if(obj.undo_pointer>maxUndos)
                obj.undo_states = obj.undo_states(end-(maxUndos-1):end,:);
                obj.undo_pointer = maxUndos;
            end
            
            curName = get(hLvdFig,'Name');
            if(~strcmpi(curName(end),'*'))
                set(hLvdFig,'Name',[curName,'*']);
            end
        end
        
        function lvdData = undo(obj, curLvdData)
            lvdData = LvdData.empty(0,1);
            if(obj.undo_pointer < 1 || obj.undo_pointer > length(obj.undo_states))
                return;
            end
            
            if(obj.undo_pointer == length(obj.undo_states))
                obj.undo_states(end+1) = LVD_UndoRedoState(curLvdData, '');
            end
            
            lvdData = obj.undo_states(obj.undo_pointer).getUndoData();
            obj.undo_pointer = obj.undo_pointer - 1;
        end
        
        function lvdData = redo(obj)
            lvdData = LvdData.empty(0,1);
            if(obj.undo_pointer + 1 < 1 || obj.undo_pointer + 2 > length(obj.undo_states))
                return;
            end
            
            lvdData = obj.undo_states(obj.undo_pointer+2).getUndoData();
            obj.undo_pointer = obj.undo_pointer + 1;
        end
        
        function [tf, undoActionName] = shouldUndoMenuBeEnabled(obj)
            if(obj.undo_pointer > 0)
                undoActionName = obj.undo_states(obj.undo_pointer).actionName;
                tf = true;
            else
                undoActionName = '';
                tf = false;
            end
        end
        
        function [tf, redoActionName] = shouldRedoMenuBeEnabled(obj)
            if(obj.undo_pointer + 1 > 0 && obj.undo_pointer + 1 < length(obj.undo_states))
                redoActionName = obj.undo_states(obj.undo_pointer+1).actionName;
                tf = true;
            else
                redoActionName = '';
                tf = false;
            end
        end
    end
end