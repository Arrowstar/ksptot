classdef LaunchVehicleEvent < matlab.mixin.SetGet
    %LaunchVehicleEvent Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        termCond(1,1) AbstractEventTerminationCondition = EventDurationTermCondition(0);
        actions(1,:) AbstractEventAction
        
        name(1,:) char = 'Untitled Event';
        script(1,:) LaunchVehicleScript
    end
    
    methods
        function obj = LaunchVehicleEvent(script)
            obj.script = script;
        end
        
        function addAction(obj, newAction)
            obj.actions(end+1) = newAction;
        end
        
        function removeAction(obj, action)
            obj.actions([obj.actions] == action) = [];
        end
        
        function removeActionByInd(obj, ind)
            if(ind >= 1 && ind <= length(obj.actions))
                obj.removeAction(obj.actions(ind));
            end
        end
        
        function action = getActionForInd(obj, ind)
            action = AbstractEventAction.empty(1,0);
            
            if(ind >= 1 && ind <= length(obj.actions))
                action = obj.actions(ind);
            end
        end
        
        function evtNum = getEventNum(obj)
            evtNum = obj.script.getNumOfEvent(obj);
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%i - %s', obj.getEventNum(), obj.name);
        end
        
        function [aListboxStr, actions] = getActionsListboxStr(obj)
            aListboxStr = {};
            actions = AbstractEventAction.empty(0,1);
            
            for(i=1:length(obj.actions)) %#ok<*NO4LP>
                aListboxStr{end+1} = obj.actions(i).getName(); %#ok<AGROW>
                actions(end+1) = obj.actions(i); %#ok<AGROW>
            end
            
%             if(isempty(aListboxStr))
%                 aListboxStr{1} = '';
%             end
        end
        
        function initEvent(obj, initialStateLogEntry)
            obj.termCond.initTermCondition(initialStateLogEntry);
        end
        
        function cleanupEvent(obj, finalStateLogEntry)
            for(i=1:length(obj.actions)) %#ok<*NO4LP>
                obj.actions(i).initAction(finalStateLogEntry);
            end
        end
        
        function newStateLogEntries = executeEvent(obj, initStateLogEntry, simDriver)
            [~,~,newStateLogEntries] = simDriver.integrateOneEvent(obj, initStateLogEntry);
            
            stateLogEntry = newStateLogEntries(end);
            for(i=1:length(obj.actions))
                newStateLogEntry = obj.actions(i).exectuteAction(stateLogEntry);
                
                newStateLogEntries(end+1) = newStateLogEntry; %#ok<AGROW>
                stateLogEntry = newStateLogEntry;
            end
        end
    end
    
    methods(Static)
        function newEvent = getDefaultEvent(script)
            newEvent = LaunchVehicleEvent(script);
            newEvent.termCond = EventDurationTermCondition(0);
        end
    end
end

