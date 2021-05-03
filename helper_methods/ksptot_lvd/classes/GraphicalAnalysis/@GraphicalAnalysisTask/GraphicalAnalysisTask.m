classdef GraphicalAnalysisTask < matlab.mixin.SetGet
    %GraphicalAnalysisTask Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        taskStr(1,:) char
        frame AbstractReferenceFrame
    end
    
    methods
        function obj = GraphicalAnalysisTask(taskStr, frame)
            obj.taskStr = taskStr;
            obj.frame = frame;
        end
        
        function listboxStr = getListBoxStr(obj)
            listboxStr = sprintf('%s [%s]', obj.taskStr, obj.frame.getNameStr());
        end
        
        function lblStr = getAxisLabel(obj)
            lblStr = {sprintf(obj.taskStr), obj.frame.getNameStr()};
        end
        
        function [depVarValue, depVarUnit, prevDistTraveled] = executeTask(obj, lvdStateLogEntry, maTaskList, prevDistTraveled, otherSCId, stationID, propNames, celBodyData)            
            cartElem = lvdStateLogEntry.getCartesianElementSetRepresentation();
            cartElem = cartElem.convertToFrame(obj.frame);
            lvdStateLogEntry.setCartesianElementSet(cartElem);
            
            refBodyId = obj.frame.getOriginBody().id;
            
            maStateLogEntry = lvdStateLogEntry.getMAFormattedStateLogMatrix(true);
            
            if(ismember(obj.taskStr,maTaskList))
                [depVarValue, depVarUnit, prevDistTraveled] = ma_getDepVarValueUnit(1, maStateLogEntry, obj.taskStr, prevDistTraveled, refBodyId, otherSCId, stationID, propNames, [], celBodyData, false);
                
            else
                [depVarValue, depVarUnit] = lvd_getDepVarValueUnit(1, lvdStateLogEntry, obj.taskStr, refBodyId, celBodyData, false, obj.frame);
            end
        end
    end
end