classdef LVD_UndoRedoState < matlab.mixin.SetGet
    %LVD_UndoRedoState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        serialLvdData uint8
        actionName char
    end
    
    methods
        function obj = LVD_UndoRedoState(lvdData, actionName)
            entries = lvdData.stateLog.entries;
            nonSeqEvtsStates = lvdData.stateLog.nonSeqEvtsStates;
            
            lvdData.stateLog.clearStateLog();
            
            obj.serialLvdData = getByteStreamFromArray(lvdData);
            obj.actionName = actionName;
            
            lvdData.stateLog.entries = entries;
            lvdData.stateLog.nonSeqEvtsStates = nonSeqEvtsStates;
        end
        
        function [lvdData, actionName] = getUndoData(obj)
            lvdData = getArrayFromByteStream(obj.serialLvdData);
            actionName = obj.actionName;
        end
    end
end