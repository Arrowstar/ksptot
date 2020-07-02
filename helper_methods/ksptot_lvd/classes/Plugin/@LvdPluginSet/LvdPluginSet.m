classdef LvdPluginSet < matlab.mixin.SetGet
    %LvdPluginSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        plugins(1,:) LvdPlugin = LvdPlugin.empty(1,0);
        
        enablePlugins(1,1) logical = true;
        
        userData
        
        lvdData LvdData
    end
    
    methods
        function obj = LvdPluginSet(lvdData)
            obj.lvdData = lvdData;
            obj.plugins = LvdPlugin.empty(1,0);
        end
        
        function addPlugin(obj, newPlugin)
            obj.plugins(end+1) = newPlugin;
        end
        
        function removePlugin(obj, plugin)
            obj.plugins([obj.plugins] == plugin) = [];
        end
        
        function listBoxStr = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.plugins))
                listBoxStr{end+1} = obj.plugins(i).pluginName; %#ok<AGROW>
            end
        end
        
        function plugins = getPluginsArray(obj)
            plugins = obj.plugins;
        end
        
        function numPlugins = getNumPlugins(obj)
            numPlugins = length(obj.plugins);
        end
        
        function movePluginAtIndexDown(obj, ind)
            if(ind < length(obj.plugins))
                obj.plugins([ind+1,ind]) = obj.plugins([ind,ind+1]);
            end
        end
        
        function movePluginAtIndexUp(obj, ind)
            if(ind > 1)
                obj.plugins([ind,ind-1]) = obj.plugins([ind-1,ind]);
            end
        end
        
        function initializePlugins(obj)
            obj.userData = [];
        end
        
        %before propagation
        function executePluginsBeforeProp(obj, stateLog)
            if(obj.enablePlugins)
                for(i=1:length(obj.plugins))
                    if(obj.plugins(i).execBeforePropTF)
                        obj.userData = obj.plugins(i).executePlugin(obj.lvdData, stateLog, LaunchVehicleEvent.empty(0,1), LvdPluginExecLocEnum.BeforeProp, [],[],[], obj.userData);
                    end
                end
            end
        end
        
        %before events
        function executePluginsBeforeEvent(obj, stateLog, event)
            if(obj.enablePlugins)
                for(i=1:length(obj.plugins))
                    if(obj.plugins(i).execBeforeEventsTF)
                        obj.userData = obj.plugins(i).executePlugin(obj.lvdData, stateLog, event, LvdPluginExecLocEnum.BeforeEvent, [],[],[], obj.userData);
                    end
                end
            end
        end
        
        %after events
        function executePluginsAfterEvent(obj, stateLog, event)
            if(obj.enablePlugins)
                for(i=1:length(obj.plugins))
                    if(obj.plugins(i).execAfterEventsTF)
                        obj.userData = obj.plugins(i).executePlugin(obj.lvdData, stateLog, event, LvdPluginExecLocEnum.AfterEvent, [],[],[], obj.userData);
                    end
                end
            end
        end
        
        %after propagation
        function executePluginsAfterProp(obj, stateLog)
            if(obj.enablePlugins)
                for(i=1:length(obj.plugins))
                    if(obj.plugins(i).execAfterPropTF)
                        obj.userData = obj.plugins(i).executePlugin(obj.lvdData, stateLog, LaunchVehicleEvent.empty(0,1), LvdPluginExecLocEnum.AfterProp, [],[],[], obj.userData);
                    end
                end
            end
        end
        
        function executePluginsAfterTimeStepOdeOutputFcn(obj, t,y,flag, eventInitStateLogEntry)
            if(obj.enablePlugins)
                for(i=1:length(obj.plugins))
                    if(obj.plugins(i).execAfterTimeStepsTF)
                        obj.userData = obj.plugins(i).executePlugin(obj.lvdData, [], eventInitStateLogEntry, LvdPluginExecLocEnum.AfterTimestep, t,y,flag, obj.userData);
                    end
                end
            end
        end
    end
end