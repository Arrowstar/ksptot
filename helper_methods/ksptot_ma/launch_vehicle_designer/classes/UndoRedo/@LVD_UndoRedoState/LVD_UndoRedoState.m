classdef LVD_UndoRedoState < matlab.mixin.SetGet
    %LVD_UndoRedoState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        serialLvdData uint8
        actionName(1,:) char
    end
    
    methods
        function obj = LVD_UndoRedoState(lvdData, actionName)
            obj.serialLvdData = getByteStreamFromArray(lvdData);
            obj.actionName = actionName;
        end
        
        function [lvdData, actionName] = getUndoData(obj)
            lvdData = getArrayFromByteStream(obj.serialLvdData);
            actionName = obj.actionName;
        end
    end
end